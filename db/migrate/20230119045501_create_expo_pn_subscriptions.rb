# frozen_string_literal: true

class CreateExpoPnSubscriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :expo_pn_subscriptions do |t|
      t.integer :user_id, null: false
      t.string :expo_pn_token, null: false
      t.string :experience_id, null: false
      t.string :application_name, null: false
      t.string :platform, null: false
      t.timestamps
    end

    add_index :expo_pn_subscriptions, [:expo_pn_token], unique: true
    add_foreign_key :expo_pn_subscriptions, :users, column: :user_id
  end
end
