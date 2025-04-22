# frozen_string_literal: true

class ExpoPushNotificationData
  attr_reader :payload, :token, :subscription

  def initialize
    @payload = default_payload
    @token = default_token
    @subscription = default_subscription
  end

  private

  def default_payload
    {
      id: 1,
      username: 'JohnDoe',
      topic_title: 'Test topic',
      excerpt: 'Test excerpt',
      notification_type: Notification.types[:mentioned],
      post_url: 'http://example.com/post',
      is_pm: false
    }
  end

  def default_token
    'ExponentPushToken[802DHLBCwOJkdEnRn_fuuG]'
  end

  def default_subscription
    {
      user_id: -1,
      expo_pn_token: token,
      experience_id: 'test-experience-id',
      application_name: 'test',
      platform: 'ios'
    }
  end
end
