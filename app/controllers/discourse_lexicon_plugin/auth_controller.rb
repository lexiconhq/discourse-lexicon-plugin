# frozen_string_literal: true

module DiscourseLexiconPlugin
  class AuthController < ::ApplicationController
    requires_plugin DiscourseLexiconPlugin::PLUGIN_NAME

    skip_before_action :redirect_to_login_if_required, raise: false # override skip action https://meta.discourse.org/t/can-i-expose-a-route-with-no-authentication/162156

    def authentication_status
      render json: {
        apple: DiscourseLexiconPlugin::Apple.enable?,
        loginLink: SiteSetting.lexicon_login_link_enabled
      }
    end
  end
end
