# frozen_string_literal: true

module DiscourseLexiconPlugin
  # The `Apple` class provides methods related to Apple authentication from site setting.
  class Apple
    def self.apple_client_id
      SiteSetting.lexicon_apple_client_id
    end

    def self.enable?
      SiteSetting.lexicon_apple_login_enabled || false
    end
  end
end
