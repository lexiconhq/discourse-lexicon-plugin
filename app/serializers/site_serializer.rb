class SiteSerializer < ApplicationSerializer
  attributes(
    :lexicon
  )

  def lexicon
    {
      settings: {
        lexicon_push_notifications_enabled: SiteSetting.lexicon_push_notifications_enabled,
        lexicon_email_deep_linking_enabled: SiteSetting.lexicon_email_deep_linking_enabled,
        lexicon_app_scheme: SiteSetting.lexicon_app_scheme.empty? ? nil : SiteSetting.lexicon_app_scheme
      }
    }
  end
end
