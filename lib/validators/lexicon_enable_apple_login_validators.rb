# frozen_string_literal: true

class LexiconEnableAppleLoginValidator
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(value)
    return false if value == 't' && SiteSetting.lexicon_apple_client_id.empty?

    true
  end

  def error_message
    I18n.t('site_settings.errors.missing_apple_client_id')
  end
end
