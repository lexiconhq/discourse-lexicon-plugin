# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/expo_push_notification_data'

RSpec.describe Jobs::ExpoPushNotification do
  let(:expo_pn_data) { ExpoPushNotificationData.new }

  def run_job(retry_ids = [])
    described_class.new.execute(payload: expo_pn_data.payload, user_id: -1, retry_ids: retry_ids)
  end

  it 'sends a push notification to the correct Expo Push Notification token' do
    PushNotificationManager.expects(:send_notification)
    expect { run_job }.to change { PushNotification.count }.by(1)
  end

  it 'sends a push notification to the correct Expo Push Notification token' do
    push_notification = PushNotification.create(expo_pn_data.payload.merge(user_id: -1))
    pn_retry = PushNotificationRetry.create(
      token: expo_pn_data.token,
      push_notification_id: push_notification.id, retry_count: 1
    )
    PushNotificationManager.expects(:send_notification)
    run_job([pn_retry.id])
  end
end
