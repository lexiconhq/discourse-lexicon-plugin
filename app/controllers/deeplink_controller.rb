# frozen_string_literal: true

class DeeplinkController < ApplicationController
  skip_before_action :redirect_to_login_if_required, raise: false # override skip action https://meta.discourse.org/t/can-i-expose-a-route-with-no-authentication/162156
  def index; end
end
