# frozen_string_literal: true

module DiscourseLexiconPlugin
  class ChatNotification
    def self.handle(message)
      channel_id, message_id = extract_ids(message)
      return unless channel_id && message_id

      message = Chat::Message.includes(:user, :chat_channel).find_by(chat_channel_id: channel_id, id: message_id)
      return unless message && message.chat_channel

      payload = build_payload(message)
      memberships = fetch_recipients(channel_id, message.user.id)

      send_push_notifications(memberships, payload)
    end

    def self.extract_ids(message)
      data = message.attributes.transform_keys(&:to_sym)
      data.values_at(:chat_channel_id, :id)
    end

    def self.build_payload(message)
      {
        notification_type: Notification.types[:chat_message],
        excerpt: message.message,
        username: message.user.username,
        post_url: "/c/#{message.chat_channel_id}#{message.thread_id ? "/#{message.thread_id}" : ''}/#{message.id}",
        is_chat: true,
        is_thread: message.thread_id.present?,
        channel_name: message.chat_channel&.name.presence || 'DM Chat'
      }
    end

    def self.fetch_recipients(channel_id, sender_id)
      # always_level = ::Chat::UserChatChannelMembership::NOTIFICATION_LEVELS[:always]

      ::Chat::UserChatChannelMembership
        .includes(:user)
        .joins(user: :user_option)
        .where(chat_channel_id: channel_id)
        .where.not(user_id: sender_id)
        .where(user_option: { chat_enabled: true })
        # .where('mobile_notification_level = ?', always_level)
        .merge(User.not_suspended)
    end

    def self.send_push_notifications(memberships, payload)
      memberships.each do |membership|
        user = membership.user
        next if user.blank? || user.suspended?

        expo_sub = ExpoPnSubscription.find_by(user_id: user.id)
        next unless expo_sub

        Jobs.enqueue(:expo_push_notification, payload: payload, user_id: user.id)
      end
    end
  end
end
