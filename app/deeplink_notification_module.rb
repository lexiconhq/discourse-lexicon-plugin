# frozen_string_literal: true

module DeeplinkNotification
  def build_email(*builder_args)
    _user_email, opts = builder_args

    update_deep_link_url(opts) if deep_linking_enabled?(opts)
    update_activation_link(opts) if activation_link_enabled?(opts)
    update_login_link(opts)

    super(*builder_args)
  end

  # Check is for email activation signup or approval register by moderator
  def activation_link_enabled?(opts)
    SiteSetting.lexicon_activate_account_link_enabled &&
      %w[user_notifications.signup user_notifications.signup_after_approval].include?(opts[:template])
  end

  def update_activation_link(opts)
    case opts[:template]
    when 'user_notifications.signup'
      opts[:base_url] = "#{Discourse.base_url}/lexicon/deeplink"
    end
  end

  def update_login_link(opts)
    case opts[:template]
    when 'user_notifications.signup_after_approval'
      opts[:base_url] = "#{Discourse.base_url}/lexicon/deeplink/login"
    end
  end

  # Check deeplink for post or private message
  def deep_linking_enabled?(opts)
    SiteSetting.lexicon_email_deep_linking_enabled &&
      opts[:template].respond_to?(:include?) &&
      opts[:template].include?('user_notifications.user_')
  end

  def update_deep_link_url(opts)
    url = opts[:url].dup
    is_pm = opts[:private_reply]
    opts[:url] = url.prepend('/lexicon/deeplink').concat("?is_pm=#{is_pm}")
  end
end
