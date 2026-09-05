# frozen_string_literal: true

class ExpoPnSubscription < ActiveRecord::Base
    belongs_to :user
    # The mobile app authenticates with a user-api-key, which creates no user auth token,
    # so a subscription can exist without one.
    belongs_to :user_auth_token, optional: true
end
