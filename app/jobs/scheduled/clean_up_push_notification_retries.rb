# frozen_string_literal: true

module Jobs
  class CleanUpPushNotificationRetries < ::Jobs::Scheduled
    every 2.hours
    sidekiq_options retry: false

    def execute(_args)
      # Delete all push notification retries that above RETRY_LIMIT
      PushNotificationRetry.where('retry_count >= ?', PushNotificationRetry.retry_limit).delete_all
      # Requeue all push notification retries whose retry_count is below `PushNotificationRetry.retry_limit` which are not yet queued or in progress
      eligible_retry_records = PushNotificationRetry.where('retry_count < ?', PushNotificationRetry.retry_limit)
      retry_records_by_push_notification_id = eligible_retry_records.group_by(&:push_notification_id)

      retry_records_by_push_notification_id.each do |push_notification_id, retry_records|
        retry_tokens = []
        retry_records.each do |retry_record|
          should_finish_retry_time = retry_record.updated_at
          next unless retry_record.retry_time < Time.current

          retry_tokens << retry_record.token
        end
        return unless retry_tokens.present?

        PushNotificationManager.retry_push_notification(tokens: retry_tokens,
                                                        push_notification_id: push_notification_id)
      end
    end
  end
end
