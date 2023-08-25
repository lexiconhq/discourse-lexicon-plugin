# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/expo_push_notification_data'
require_relative '../support/expo_push_notification_error'

describe PushNotificationManager do
  let(:expo_pn_data) { ExpoPushNotificationData.new }
  let(:expo_pn_error) { ExpoPushNotificationError.new }

  def run_process_tickets(error_tickets, push_notification, retry_ids: [], tokens: [expo_pn_data.token])
    PushNotificationManager.process_tickets(error_tickets, push_notification, retry_ids: retry_ids, tokens: tokens)
  end

  context 'if ticket type is TicketsWithError' do
    def create_tickets_with_error(error)
      error_ticket = Expo::Push::TicketsWithErrors.new(data: [], errors: [error])
      Expo::Push::Tickets.new([error_ticket])
    end

    context 'if error code PUSH_TOO_MANY_EXPERIENCE_IDS' do
      let(:error_tickets) { create_tickets_with_error(expo_pn_error.push_too_many_exp_id) }

      it 'creates a new push notification retry' do
        push_notification = PushNotification.create(expo_pn_data.payload.merge(user_id: -1))
        expect { run_process_tickets(error_tickets, push_notification) }.to change {
                                                                              PushNotificationRetry.count
                                                                            }.by(1)
      end

      it 'logs an error when maximum retry count is reached' do
        push_notification = PushNotification.create(expo_pn_data.payload.merge(user_id: -1))
        pn_retry = PushNotificationRetry.create(token: expo_pn_data.token,
                                                push_notification_id: push_notification.id, retry_count: 9)

        Rails.logger.expects(:error).with("PushNotificationManger: Excessive retries for push_notification_id: #{push_notification.id}")
        expect { run_process_tickets(error_tickets, push_notification, retry_ids: [pn_retry.id]) }.to change {
                                                                                                        PushNotificationRetry.count
                                                                                                      }.by(-1)
      end
    end

    it 'logs an error for other error codes' do
      error_tickets = create_tickets_with_error(expo_pn_error.validation)
      push_notification = PushNotification.create(expo_pn_data.payload.merge(user_id: -1))

      Rails.logger.expects(:error).with("PushNotificationManger: #{expo_pn_error.validation}")
      run_process_tickets(error_tickets, push_notification)
    end
  end

  it 'handles a send request with error ticket' do
    subscription = expo_pn_data.subscription
    ExpoPnSubscription.create!(
      user_id: subscription[:user_id],
      expo_pn_token: expo_pn_data.token,
      experience_id: subscription[:experience_id],
      application_name: subscription[:application_name],
      platform: subscription[:platform]
    )
    error_ticket = Expo::Push::Ticket.new(expo_pn_error.device_not_registered, expo_pn_data.token)
    tickets = Expo::Push::Tickets.new([[error_ticket]])
    push_notification = PushNotification.create(expo_pn_data.payload.merge(user_id: -1))

    expect { run_process_tickets(tickets, push_notification) }.to change { ExpoPnSubscription.count }.by(-1)
  end
end
