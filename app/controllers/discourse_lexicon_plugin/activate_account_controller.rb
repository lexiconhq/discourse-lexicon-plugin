# frozen_string_literal: true

module DiscourseLexiconPlugin
  class ActivateAccountController < ::ApplicationController
    skip_before_action :redirect_to_login_if_required, raise: false # override skip action https://meta.discourse.org/t/can-i-expose-a-route-with-no-authentication/162156

    def honeypot_or_challenge_fails?(params)
      return false if is_api?

      params[:password_confirmation] != honeypot_value ||
        params[:challenge] != challenge_value.try(:reverse)
    end

    def perform_account_activation
      raise Discourse::InvalidAccess if honeypot_or_challenge_fails?(params)

      unless @user = EmailToken.confirm(params[:token], scope: EmailToken.scopes[:signup])
        return render json: { error: I18n.t('activation.already_done') }
      end

      # Log in the user unless they need to be approved
      if Guardian.new(@user).can_access_forum?
        log_on_user(@user)

        return render_serialized(@user, UserSerializer)
      end

      render json: { error: 'need approval from moderator' }
    end
  end
end
