# frozen_string_literal: true

module DiscourseLexiconPlugin
  class UserController < ::ApplicationController
    def get_current_user
      render json: current_user
    end
  end
end
