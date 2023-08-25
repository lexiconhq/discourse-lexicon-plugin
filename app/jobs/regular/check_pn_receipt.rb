# frozen_string_literal: true

module Jobs
  class CheckPnReceipt < ::Jobs::Base
    # We have a custom retry implementation, so this prevents Sidekiq from automatically retrying the jobs alongside our manual retry.
    sidekiq_options retry: false
    def execute(args)
      push_notification_receipt_ids = args[:push_notification_receipt_ids]
      # get PushNotificationReceipt records
      push_notification_receipts = PushNotificationReceipt.where(id: push_notification_receipt_ids)
      # get the receipt_ids
      receipt_ids = push_notification_receipts.map(&:receipt_id)
      client = Expo::Push::Client.new
      receipts = client.receipts(receipt_ids)

      ReceiptsManager.process_receipts(
        receipts
      )
    end
  end
end
