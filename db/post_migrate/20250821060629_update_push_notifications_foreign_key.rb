# frozen_string_literal: true

class UpdatePushNotificationsForeignKey < ActiveRecord::Migration[6.1]
  def up
    remove_foreign_key :push_notifications, column: :user_id
    add_foreign_key :push_notifications, :users, column: :user_id, on_delete: :cascade
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
