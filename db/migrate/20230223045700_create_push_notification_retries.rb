# frozen_string_literal: true

class CreatePushNotificationRetries < ActiveRecord::Migration[6.1]
  def change
    create_table :push_notification_retries do |t|
      # This array columnn only work in postgres
      # https://stackoverflow.com/questions/21312278/storing-arrays-in-database-json-vs-serialized-array
      t.string :token
      t.integer :push_notification_id
      t.integer :retry_count, default: 0
      t.integer :lock_version, default: 0, null: false
      t.timestamps
    end

    add_foreign_key :push_notification_retries, :push_notifications, column: :push_notification_id
  end
end
