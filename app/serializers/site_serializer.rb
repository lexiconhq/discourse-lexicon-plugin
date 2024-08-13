class SiteSerializer < ApplicationSerializer
  attributes(
    :lexicon
  )

  def lexicon
    {
      settings: {
        lexicon_push_notifications_enabled: SiteSetting.lexicon_push_notifications_enabled,
        lexicon_email_deep_linking_enabled: SiteSetting.lexicon_email_deep_linking_enabled,
        lexicon_app_scheme: SiteSetting.lexicon_app_scheme.empty? ? nil : SiteSetting.lexicon_app_scheme,
        lexicon_apple_login_enabled: SiteSetting.lexicon_apple_login_enabled,
        lexicon_apple_client_id: SiteSetting.lexicon_apple_client_id,
        lexicon_activate_account_link_enabled: SiteSetting.lexicon_activate_account_link_enabled,
        lexicon_login_link_enabled: SiteSetting.lexicon_login_link_enabled
      }
    }
  end
end
