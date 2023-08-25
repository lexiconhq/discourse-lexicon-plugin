# frozen_string_literal: true

class EditExpoPnSubscriptions < ActiveRecord::Migration[6.1]
  def change
    add_column :expo_pn_subscriptions, :user_auth_token_id, :integer
    add_foreign_key :expo_pn_subscriptions, :user_auth_tokens, column: :user_auth_token_id, on_delete: :cascade
  end
end
