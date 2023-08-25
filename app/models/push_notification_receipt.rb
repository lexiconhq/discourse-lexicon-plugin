# frozen_string_literal: true

class PushNotificationReceipt < ActiveRecord::Base
  belongs_to :push_notification
end
