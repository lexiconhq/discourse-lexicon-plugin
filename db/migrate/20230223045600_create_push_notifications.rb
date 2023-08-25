# frozen_string_literal: true

class CreatePushNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :push_notifications do |t|
      t.integer :user_id
      t.string :username
      t.string :topic_title
      t.string :excerpt
      t.string :notification_type
      t.string :post_url
      t.boolean :is_pm
      t.timestamps
    end

    add_foreign_key :push_notifications, :users, column: :user_id
  end
end
