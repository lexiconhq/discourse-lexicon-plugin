# frozen_string_literal: true

class EditPushNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :push_notifications, :is_chat, :boolean
    add_column :push_notifications, :channel_name, :string
    add_column :push_notifications, :is_thread, :boolean
  end
end
