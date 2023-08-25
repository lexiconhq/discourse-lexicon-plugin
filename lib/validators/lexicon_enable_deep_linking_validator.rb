# frozen_string_literal: true

class LexiconEnableDeepLinkingValidator
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(value)
    return false if value == "t" && SiteSetting.lexicon_app_scheme.empty? 
    true
  end

  def error_message
    I18n.t("site_settings.errors.missing_app_scheme")
  end
end
  