# frozen_string_literal: true

class LexiconAppSchemeValidator
  # Scheme names consist of a sequence of characters beginning with a letter and followed
  # by any combination of letters, digits, plus ("+"), period ("."), or hyphen ("-")
  APP_SCHEME_REGEX = /^[A-Za-z][A-Za-z0-9+-.]*$/
  MIN_APP_SCHEME_LENGTH = 3
  MAX_APP_SCHEME_LENGTH = 2000

  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(value)
    @error_type = ''
    if value.present?
      if value.match(APP_SCHEME_REGEX) && (MIN_APP_SCHEME_LENGTH..MAX_APP_SCHEME_LENGTH).include?(value.length)
        true
      else
        @error_type = 'wrong_format' unless value.match(APP_SCHEME_REGEX)
        @error_type = 'min_length' if value.length < MIN_APP_SCHEME_LENGTH
        @error_type = 'max_length' if value.length > MAX_APP_SCHEME_LENGTH
        false
      end
    elsif SiteSetting.lexicon_email_deep_linking_enabled.present? || SiteSetting.lexicon_login_link_enabled.present?
      @error_type = 'missing_app_scheme'
      false
    else
      true
    end
  end

  def error_message
    case @error_type
    when 'missing_app_scheme'
      I18n.t('site_settings.errors.missing_app_scheme')
    when 'wrong_format'
      I18n.t('site_settings.errors.wrong_format_app_scheme')
    when 'min_length'
      I18n.t('site_settings.errors.min_app_scheme_length')
    when 'max_length'
      I18n.t('site_settings.errors.max_app_scheme_length')
    end
  end
end
