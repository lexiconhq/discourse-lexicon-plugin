## frozen_string_literal: true

class PushNotificationCleanup
  def initialize(user)
    @user = user
  end

  def delete_lexicon_plugin_data
    push_notification_ids = fetch_push_notification_ids_by_user

    delete_push_notification_receipts(push_notification_ids)
    delete_push_notification_retries(push_notification_ids)
    delete_push_notifications(push_notification_ids)
  end

  private

  def fetch_push_notification_ids_by_user
    PushNotification.where(user_id: @user.id).pluck(:id)
  end

  def delete_push_notifications(ids)
    return if ids.empty?

    PushNotification.where(id: ids).delete_all
  rescue StandardError => e
    Rails.logger.error("Failed to delete push notifications: #{e.message}")
  end

  def delete_push_notification_retries(ids)
    return if ids.empty?

    PushNotificationRetry.where(push_notification_id: ids).delete_all
  rescue StandardError => e
    Rails.logger.error("Failed to delete push notification retries: #{e.message}")
  end

  def delete_push_notification_receipts(ids)
    return if ids.empty?

    PushNotificationReceipt.where(push_notification_id: ids).delete_all
  rescue StandardError => e
    Rails.logger.error("Failed to delete push notification receipts: #{e.message}")
  end
end
