# frozen_string_literal: true

module DiscourseLexiconPlugin
  class Engine < ::Rails::Engine
    engine_name "DiscourseLexiconPlugin".freeze
    isolate_namespace DiscourseLexiconPlugin
    
    config.after_initialize do
      Discourse::Application.routes.append do
        mount ::DiscourseLexiconPlugin::Engine, at: "/lexicon/push_notifications"
      end
    end
  end
end
