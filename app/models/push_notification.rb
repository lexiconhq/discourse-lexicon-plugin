# frozen_string_literal: true

class PushNotification < ActiveRecord::Base
  has_many :push_notification_retries
  has_many :push_notification_receipts
end
