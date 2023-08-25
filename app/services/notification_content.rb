class NotificationContent
  def self.generate_notification_content(notification_type, sender, topic_title, excerpt)
    notification_variations = {
      Notification.types[:mentioned] => {
        text: "mentioned you",
        body: :excerpt
      },
      Notification.types[:replied] => {
        text: "replied to your post",
        body: :excerpt
      },
      Notification.types[:private_message] => {
        text: "sent you a message",
        body: :excerpt
      },
      Notification.types[:posted] => {
        text: "posted in",
        body: :excerpt
      },
      Notification.types[:linked] => {
        text: "linked to your post",
        body: :excerpt
      },
      Notification.types[:liked] => {
        text: "liked your post",
        body: :excerpt
      },
      Notification.types[:quoted] => {
        text: "quoted your post",
        body: :excerpt
      }
    }

    variation = notification_variations[notification_type.to_i] || { text: topic_title }

    title = variation[:body] == :excerpt ? "#{sender} #{variation[:text]} - #{topic_title}" : variation[:text]
    body = variation[:body] == :excerpt ? excerpt : "#{sender}: #{excerpt}"

    { title: title, body: body }
  end
end
