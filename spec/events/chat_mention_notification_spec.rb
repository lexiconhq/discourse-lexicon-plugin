# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseLexiconPlugin::ChatMentionNotification do
  subject { described_class.handle(notification) }

  let(:user) { Fabricate(:user) }
  let(:chat_channel) { Fabricate(:chat_channel) }
  let(:message) { Fabricate(:chat_message, chat_channel: chat_channel, user: user) }
  let(:notification_data) { { chat_channel_id: chat_channel.id, chat_message_id: message.id }.to_json }
  let(:notification) do
    Notification.new(notification_type: notification_type, user_id: user.id, data: notification_data)
  end
  let(:notification_type) { Notification.types[:chat_mention] } # Default type for valid test
  let(:expo_pn_data) { ExpoPushNotificationData.new }

  context 'when the notification type is chat_mention' do
    before do
      subscription_data = expo_pn_data.subscription.merge(user_id: user.id) # Override user_id
      # Ensure a subscription exists for the user
      ExpoPnSubscription.create!(subscription_data)
    end

    it 'enqueues a job for expo push notification' do
      expect { subject }.to change { Jobs::ExpoPushNotification.jobs.size }.by(1)

      job = Jobs::ExpoPushNotification.jobs.first
      expect(job['args'].first['user_id']).to eq(user.id)
      expect(job['args'].first['payload']).to include(
        'notification_type' => Notification.types[:chat_mention],
        'excerpt' => message.message,
        'username' => user.username,
        'post_url' => "/c/#{chat_channel.id}/#{message.id}",
        'is_chat' => true,
        'is_thread' => message.thread_id.present?,
        'channel_name' => chat_channel.name
      )
    end
  end

  context 'when the notification type is not chat_mention' do
    let(:notification_type) { Notification.types[:mentioned] } # Change to an invalid type

    it 'does not enqueue a job' do
      expect { subject }.not_to(change { Jobs::ExpoPushNotification.jobs.size })
    end
  end

  context 'when the message is not found' do
    let(:notification_data) { { chat_channel_id: chat_channel.id, chat_message_id: -1 }.to_json }

    it 'does not enqueue a job' do
      expect { subject }.not_to(change { Jobs::ExpoPushNotification.jobs.size })
    end
  end

  context 'when user subscription is not found' do
    it 'does not enqueue a job' do
      expect { subject }.not_to(change { Jobs::ExpoPushNotification.jobs.size })
    end
  end
end
