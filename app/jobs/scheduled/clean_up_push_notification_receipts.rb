# frozen_string_literal: true

module Jobs
  class CleanUpPushNotificationReceipts < ::Jobs::Scheduled
    every 2.hours
    sidekiq_options retry: false

    def execute(_args)
      # Delete push notification receipts older than 1 day
      PushNotificationReceipt.where('created_at < ?', 1.day.ago).delete_all
      # Requeue receipt that exist ( 20 minutes ago chosen as receipt should be processed after 15 minutes)
      receipts = PushNotificationReceipt.where('created_at < ?', 20.minute.ago)
      receipt_ids = receipts.map(&:id)
      Jobs.enqueue(:check_pn_receipt, push_notification_receipt_ids: receipt_ids)
    end
  end
end
