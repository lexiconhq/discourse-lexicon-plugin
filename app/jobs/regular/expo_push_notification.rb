# frozen_string_literal: true

module Jobs
  class ExpoPushNotification < ::Jobs::Base
    # We have a custom retry implementation, so this prevents Sidekiq from automatically retrying the jobs alongside our manual retry.
    sidekiq_options retry: false
    def execute(args)
      if args[:retry_ids].blank?
        payload = args[:payload]
        expo_pn_subscriptions = ExpoPnSubscription.where(user_id: args[:user_id])
        push_notification = ::PushNotification.create(
          user_id: args[:user_id],
          username: payload[:username],
          topic_title: payload[:topic_title],
          excerpt: payload[:excerpt],
          notification_type: payload[:notification_type],
          post_url: payload[:post_url],
          is_pm: payload[:is_pm]
        )
        PushNotificationManager.send_notification(push_notification: push_notification,
                                                  expo_pn_subscriptions: expo_pn_subscriptions)
      else
        # get all push_notification_retries
        push_notification_retries = PushNotificationRetry.where(id: args[:retry_ids])
        # group by push_notification_id
        retries_by_push_notification_id = push_notification_retries.group_by(&:push_notification_id)

        # loop through each push_notification_id
        retries_by_push_notification_id.each do |_push_notification_id, retries|
          # get all expo_pn_subscriptions for the tokens
          expo_pn_subscriptions = ExpoPnSubscription.where(
            expo_pn_token: retries.map(&:token)
          )
          # this push_notification_id should be the same for all retries since we already grouped above
          push_notification = push_notification_retries[0].push_notification

          PushNotificationManager.send_notification(push_notification: push_notification,
                                                    expo_pn_subscriptions: expo_pn_subscriptions)
        end

      end
    end
  end
end
