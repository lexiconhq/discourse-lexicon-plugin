# frozen_string_literal: true

module DiscourseLexiconPlugin
  class ExpoPnController < ::ApplicationController
    requires_plugin DiscourseLexiconPlugin::PLUGIN_NAME

    def subscribe
      expo_pn_token = params.require(:push_notifications_token)
      application_name = params.require(:application_name)
      platform = params.require(:platform)
      experience_id = params.require(:experience_id)

      if %w[ios android].exclude?(platform)
        raise Discourse::InvalidParameters,
              "\"platform\" must be \"ios\" or \"android\"."
      end

      ExpoPnSubscription
        .where(expo_pn_token: expo_pn_token)
        .destroy_all

      record =
        ExpoPnSubscription.find_or_create_by(
          user_id: current_user.id,
          expo_pn_token: expo_pn_token,
          application_name: application_name,
          platform: platform,
          experience_id: experience_id,
          user_auth_token_id: current_user.user_auth_tokens&.last&.id
        )
      # return the expo_pn_token and user_id
      # so that the client can utilize it if needed
      render json: {
               expo_pn_token: record.expo_pn_token,
               user_id: record.user_id
             }
    end

    def unsubscribe
      expo_pn_token = params.require(:push_notifications_token)

      ExpoPnSubscription
        .where(expo_pn_token: expo_pn_token, user_id: current_user.id)
        .delete_all

      # return success if there are no error
      render json: {
               message: "success"
             }
    end
  end
end
