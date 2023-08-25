class ReceiptsManager
  def self.queue_receipts(tickets, push_notification)
    token_by_receipt_id = tickets.token_by_receipt_id
    batches = tickets.batch_ids
    batches.each do |current_batch_receipt_ids|
      push_notification_receipt_ids = []
      current_batch_receipt_ids.each do |receipt_id|
        expo_pn_token = token_by_receipt_id[receipt_id]
        push_notification_receipt = PushNotificationReceipt.create(receipt_id: receipt_id, token: expo_pn_token,
                                                                   push_notification_id: push_notification.id)
        push_notification_receipt_ids << push_notification_receipt.id
      end
      Jobs.enqueue_in(15.minutes, :check_pn_receipt, push_notification_receipt_ids: push_notification_receipt_ids)
    end
  end

  def self.process_receipts(receipts)
    device_not_registered_receipts = []
    successful_receipts = []
    retryable_receipts = []
    # group receipt errors
    receipts.each_error do |receipt_error|
      if receipt_error.is_a?(Expo::Push::ReceiptsWithErrors)
        receipt_error.errors.each do |error_data|
          Rails.logger.error('PushNotificationManger: ' + error_data.to_s)
        end
      elsif receipt_error.respond_to?(:error_message)
        if receipt_error.error_message == 'DeviceNotRegistered'
          device_not_registered_receipts << receipt_error.receipt_id
        elsif receipt_error.error_message == 'MessageRateExceeded'
          retryable_receipts << receipt_error.receipt_id
        end
      else
        Rails.logger.error('PushNotificationManger: ' + receipt_error.to_s)
      end
    end
    # group successful receipts
    receipts.each do |receipt|
      successful_receipts << receipt.receipt_id
    end

    cleanup_device_not_registered_receipts(device_not_registered_receipts) if device_not_registered_receipts.present?

    retry_receipts(retryable_receipts) if retryable_receipts.present?

    process_finished_receipts(successful_receipts) if successful_receipts.present?
  end

  def self.retry_receipts(receipt_ids)
    push_notification_receipts = PushNotificationReceipt.where(receipt_id: receipt_ids)
    push_notification = push_notification_receipts.first.push_notification
    # get all tokens from push_notification_receipts
    tokens = push_notification_receipts.map(&:token)
    # retry push notification
    PushNotificationManager.retry_push_notification(tokens: tokens, push_notification_id: push_notification.id)
    # destroy all push_notification_receipts
    push_notification_receipts.destroy_all
  end

  def self.cleanup_device_not_registered_receipts(receipt_ids)
    # find all push_notification_receipts with receipt_id in device_not_registered_receipts
    push_notification_receipts = PushNotificationReceipt.where(receipt_id: receipt_ids)
    # delete all ExpoSubscriptions with push_notification_receipts.token
    ExpoPnSubscription.where(expo_pn_token: push_notification_receipts.map(&:token)).destroy_all
    process_finished_receipts(receipt_ids)
  end

  def self.process_finished_receipts(receipt_ids)
    # find all push_notification_receipts with receipt_id in receipt_ids
    push_notification_receipts = PushNotificationReceipt.where(receipt_id: receipt_ids)
    # get push notification id
    push_notification_id = push_notification_receipts.first.push_notification_id
    # destroy all push_notification_retries with push_notification_receipts.token and push_notification_receipts.push_notification_id
    PushNotificationRetry.where(token: push_notification_receipts.map(&:token),
                                push_notification_id: push_notification_id).destroy_all
    # destroy all push_notification_receipts
    push_notification_receipts.destroy_all
  end
end
