# frozen_string_literal: true

module DeeplinkNotification
  def build_email(*builder_args)
    _user_email, opts = builder_args

    if SiteSetting.lexicon_email_deep_linking_enabled && (opts.key?(:template) && opts[:template].respond_to?(:include?) && (opts[:template].include? 'user_notifications.user_'))
      url = opts[:url].dup
      is_pm = opts[:private_reply]
      opts[:url] = url.prepend('/lexicon/deeplink').concat("?is_pm=#{is_pm}")
    end

    super(*builder_args)
  end
end
