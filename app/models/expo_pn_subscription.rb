# frozen_string_literal: true

class ExpoPnSubscription < ActiveRecord::Base
    belongs_to :user
    belongs_to :user_auth_token
end
