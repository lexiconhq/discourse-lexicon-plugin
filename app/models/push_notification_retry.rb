# frozen_string_literal: true

# a buffer time for maximum time we expect sending push notification job finished
# from the time the job is enqueued
BUFFER_TIME = 5.minutes
# maximum retry count
RETRY_LIMIT = 10

class PushNotificationRetry < ActiveRecord::Base
  belongs_to :push_notification
  # retry time calculation with exponential backoff
  def self.calculate_retry_time(retry_count)
    1.minute * 2**retry_count
  end

  def self.retry_limit
    RETRY_LIMIT
  end

  def retry_time
    updated_at + PushNotificationRetry.calculate_retry_time(retry_count) + BUFFER_TIME
  end

  def eligible_to_retry
    retry_count < RETRY_LIMIT
  end
end
