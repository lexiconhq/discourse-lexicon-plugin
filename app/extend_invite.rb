# frozen_string_literal: true

# This module overrides the default Invite#link method
# to provide a custom invite URL for Lexicon use cases.

require_dependency 'invite'

module DiscourseLexiconPlugin
  module InviteExtension
    def link(with_email_token: false)
      if SiteSetting.lexicon_invites_link_enabled
        if with_email_token
          "#{Discourse.base_url}/lexicon/deeplink/invites/#{invite_key}?t=#{email_token}"
        else
          "#{Discourse.base_url}/lexicon/deeplink/invites/#{invite_key}"
        end
      else
        # Fallback to Discourse's original behavior
        super
      end
    end
  end
end

::Invite.prepend DiscourseLexiconPlugin::InviteExtension
