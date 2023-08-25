# frozen_string_literal: true

class CreatePushNotificationReceipts < ActiveRecord::Migration[6.1]
  def change
    create_table :push_notification_receipts do |t|
      t.integer :push_notification_id
      t.string :token
      t.string :receipt_id
      t.timestamps
    end

    add_index :push_notification_receipts, [:receipt_id], unique: true
    add_foreign_key :push_notification_receipts, :push_notifications, column: :push_notification_id
  end
end
