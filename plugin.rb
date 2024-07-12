# frozen_string_literal: true

# name: discourse-lexicon-plugin
# about: Official Discourse plugin for Lexicon (https://lexicon.is)
# version: 2.0
# authors: kodefox
# url: https://github.com/kodefox/discourse-lexicon-plugin

# We need to load all external packages first
# Reference: https://meta.discourse.org/t/plugin-using-own-gem/50007/4
gem 'rake', '13.2.1'
gem 'connection_pool', '2.4.1'
gem 'unf_ext', '0.0.9.1'
gem 'unf', '0.1.4'
gem 'domain_name', '0.5.20190701'
gem 'http-cookie', '1.0.5'
gem 'ffi', '1.17.0'
gem 'public_suffix', '6.0.0'
gem 'addressable', '2.8.7'
gem 'ffi-compiler', '1.0.1', require_name: 'ffi-compiler/loader'
gem 'llhttp-ffi', '0.4.0', require_name: 'llhttp'
gem 'http-form_data', '2.3.0', require_name: 'http/form_data'
gem 'http', '5.1.0'
require_relative 'lib/expo_server_sdk_ruby/expo/server/sdk'

enabled_site_setting :lexicon_push_notifications_enabled
enabled_site_setting :lexicon_email_deep_linking_enabled
enabled_site_setting :lexicon_app_scheme

load File.expand_path('lib/discourse-lexicon-plugin/engine.rb', __dir__)

# Site setting validators must be loaded before initialize
require_relative 'lib/validators/lexicon_enable_deep_linking_validator'
require_relative 'lib/validators/lexicon_app_scheme_validators'

after_initialize do
  load File.expand_path('app/controllers/deeplink_controller.rb', __dir__)
  load File.expand_path('app/deeplink_notification_module.rb', __dir__)
  load File.expand_path('app/serializers/site_serializer.rb', __dir__)

  if SiteSetting.lexicon_push_notifications_enabled
    load File.expand_path('app/jobs/regular/expo_push_notification.rb', __dir__)
    load File.expand_path('app/jobs/regular/check_pn_receipt.rb', __dir__)
    load File.expand_path('app/jobs/scheduled/clean_up_push_notification_retries.rb', __dir__)
    load File.expand_path('app/jobs/scheduled/clean_up_push_notification_receipts.rb', __dir__)

    User.class_eval { has_many :expo_pn_subscriptions, dependent: :delete_all }

    DiscourseEvent.on(:before_create_notification) do |user, type, post|
      if user.expo_pn_subscriptions.exists?
        payload = {
          notification_type: type,
          post_number: post.post_number,
          topic_title: post.topic.title,
          topic_id: post.topic.id,
          excerpt:
            nil ||
            post.excerpt(
              400,
              text_entities: true,
              strip_links: true,
              remap_emoji: true
            ),
          username: nil || post.username,
          post_url: post.url,
          is_pm: post.topic.private_message?
        }
        Jobs.enqueue(
          :expo_push_notification,
          payload: payload,
          user_id: user.id
        )
      end
    end
  end

  Discourse::Application.routes.append do
    get '/deeplink/*link' => 'deeplink#index'
  end
  UserNotifications.class_eval { prepend DeeplinkNotification }
end
