# frozen_string_literal: true

class LexiconAppleClientIdValidator
  # Bundle ID names consist of a sequence of characters beginning with a letter and followed
  # by any combination of letters, digits, plus ("+"), period ("."), or hyphen ("-").
  # for more detail check https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleidentifier#discussion
  APPLE_CLIENT_ID_REGEX = /^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/
  MIN_APPLE_CLIENT_ID_LENGTH = 10
  MAX_APPLE_CLIENT_ID_LENGTH = 155

  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(value)
    @error_type = ''
    if value.present?
      unless valid_format?(value) && valid_length?(value)
        set_error_type(value)
        return false
      end
    elsif SiteSetting.lexicon_apple_login_enabled.present?
      @error_type = 'missing_apple_client_id'
      return false
    end
    true
  end

  def error_message
    case @error_type
    when 'missing_apple_client_id'
      I18n.t('site_settings.errors.missing_apple_client_id')
    when 'wrong_format'
      I18n.t('site_settings.errors.wrong_format_apple_client_id')
    when 'min_length'
      I18n.t('site_settings.errors.min_apple_client_id_length')
    when 'max_length'
      I18n.t('site_settings.errors.max_apple_client_id_length')
    end
  end

  private

  def valid_format?(value)
    value.match(APPLE_CLIENT_ID_REGEX)
  end

  def valid_length?(value)
    (MIN_APPLE_CLIENT_ID_LENGTH..MAX_APPLE_CLIENT_ID_LENGTH).cover?(value.length)
  end

  def set_error_type(value)
    @error_type = 'wrong_format' unless valid_format?(value)
    @error_type = 'min_length' if value.length < MIN_APPLE_CLIENT_ID_LENGTH
    @error_type = 'max_length' if value.length > MAX_APPLE_CLIENT_ID_LENGTH
  end
end
