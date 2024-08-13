# frozen_string_literal: true

module DiscourseLexiconPlugin
  class AppleAuthController < ::ApplicationController
    requires_plugin DiscourseLexiconPlugin::PLUGIN_NAME

    skip_before_action :redirect_to_login_if_required, raise: false # override skip action https://meta.discourse.org/t/can-i-expose-a-route-with-no-authentication/162156

    ACTIVATE_USER_KEY = 'activate_user'
    VALID_APPLE_ISS = 'https://appleid.apple.com'

    # session function from discourse for check how to use see `https://github.com/discourse/discourse/blob/main/app/controllers/session_controller.rb`

    # create new token and cookie
    def login_call(user)
      session.delete(ACTIVATE_USER_KEY)
      user.update_timezone_if_missing(params[:timezone])
      log_on_user(user)
      render_serialized(user, UserSerializer)
    end

    # error if user not active
    def not_activated(user)
      session[ACTIVATE_USER_KEY] = user.id
      render json: {
        error: I18n.t('login.not_activated'),
        reason: 'not_activated'
      }
    end

    # error message if user get suspended
    def suspend_user(user)
      { error: user.suspended_message, reason: 'suspended' }
    end

    def login_not_approved
      { error: I18n.t('login.not_approved') }
    end

    def login_not_approved_for?(user)
      SiteSetting.must_approve_users? && !user.approved? && !user.admin?
    end

    def fetch_apple_jwks
      Discourse
        .cache
        .fetch('sign-in-with-apple-jwks', expires_in: 1.day) do
        connection = Faraday.new { |c| c.use Faraday::Response::RaiseError }
        # Apple provides public keys to validate tokens
        JSON.parse(
          connection.get('https://appleid.apple.com/auth/keys').body,
          symbolize_names: true
        )
      end
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.error("Unable to fetch sign-in-with-apple-jwks #{e.class} #{e.message}")
      nil
    end

    # validate iss token to valid the value must https://appleid.apple.com
    def valid_iss?(decoded_token)
      decoded_token['iss'] == VALID_APPLE_ISS
    end

    # validate audience from token which bundle id from app
    def valid_aud?(decoded_token)
      client_id = DiscourseLexiconPlugin::Apple.apple_client_id
      decoded_token['aud'] == client_id
    end

    # Validate Apple token using 'jwt' gem
    def validate_apple_token(token)
      jwks = fetch_apple_jwks
      decoded_token = JWT.decode(
        token,
        nil,
        true, # validate token
        algorithms: ['RS256'],
        jwks: jwks
      )[0]

      if decoded_token && valid_iss?(decoded_token) && valid_aud?(decoded_token)
        decoded_token
      else
        Rails.logger.error('Invalid iss')
        false
      end
    rescue JWT::VerificationError, JWT::DecodeError, StandardError => e
      # Log or handle the error as needed
      Rails.logger.error("Error validating Apple token: #{e.message}")
      false
    end

    def login
      enable_feature_apple_auth = DiscourseLexiconPlugin::Apple.enable?

      # return error when feature not enable
      return render json: { error: 'Apple authentication feature is not enabled' } unless enable_feature_apple_auth

      apple_token = params.require(:id_token)

      # will return result of decoded token if success
      decoded_token = validate_apple_token(apple_token)
      unless decoded_token
        render json: {
          error: 'Apple Token Not Valid'
        }
        return
      end
      email = decoded_token['email']

      # Search is email already register in discourse db
      user_with_email = User.find_by_email(email)
      if user_with_email

        if login_not_approved_for?(user_with_email)
          render json: login_not_approved
          return
        end

        if user_with_email.suspended?
          render json: suspend_user(user_with_email)
          return
        end

        if user_with_email.active && user_with_email.email_confirmed?
          login_call(user_with_email)
        else
          not_activated(user_with_email)
        end

      else
        # Return an error if the user is not found
        render json: {
          error: 'Email not found'
        }
      end
    end
  end
end
