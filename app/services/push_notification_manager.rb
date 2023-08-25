## frozen_string_literal: true

class PushNotificationManager
  def self.send_notification(push_notification:, expo_pn_subscriptions:)
    sender = push_notification.username
    topic_title = push_notification.topic_title
    excerpt = push_notification.excerpt
    notification_type = push_notification.notification_type
    post_url = push_notification.post_url
    is_pm = push_notification.is_pm

    content = NotificationContent.generate_notification_content(notification_type, sender, topic_title, excerpt)
    title = content[:title]
    body = content[:body]

    client = Expo::Push::Client.new
    experience_id_group = build_experience_id_groups(expo_pn_subscriptions)

    experience_id_group.each do |_experience_id, expo_pn_tokens|
      messages = []

      expo_pn_tokens.each do |expo_pn_token|
        unless Expo::Push.expo_push_token?(expo_pn_token)
          Rails.logger.error(
            "Push token #{expo_pn_token} is not a valid Expo push token"
          )
          ExpoPnSubscription.where(expo_pn_token: expo_pn_token).destroy_all
          next
        end
        messages << client
                    .notification
                    .to(expo_pn_token)
                    .sound('default')
                    .title(title)
                    .body(body)
                    .data(
                      {
                        'discourse_url' => post_url,
                        'type' => notification_type,
                        'is_pm' => is_pm
                      }
                    )
      end

      tickets = client.send(messages)
      # Error handling
      process_tickets(
        tickets,
        push_notification,
        tokens: expo_pn_tokens
      )
    end
  end

  def self.process_tickets(tickets, push_notification, opts)
    should_retry = false
    # handle ticket errors
    tickets.each_error do |ticket_error|
      if ticket_error.is_a?(Expo::Push::PushTokenInvalid)
        # Destroy the tokens that match because they are not valid
        ExpoPnSubscription.where(expo_pn_token: ticket_error.token).destroy_all
      elsif ticket_error.is_a?(Expo::Push::TicketsWithErrors)
        ticket_error.errors.each do |error_data|
          should_retry = true
          if error_data['code'] == 'PUSH_TOO_MANY_EXPERIENCE_IDS'
            # Go through all the details
            error_data['details'].each do |correct_experience, tokens|
              # Find the incorrect instances
              # Do note that we still fail to send the notification and this need to be retried
              instances =
                ExpoPnSubscription
                .where.not(experience_id: correct_experience)
                .where(expo_pn_token: tokens)
              next if instances.blank?

              next if instances.update_all(experience_id: correct_experience)

              # We failed to update the experience_id
              Rails.logger.error(
                'PushNotificationManger: Failed to update experience_id with tokens ' +
                  tokens.to_s
              )
              next
              # experience_id successfully updated
            end
          else
            # Request error is not PUSH_TOO_MANY_EXPERIENCE_IDS
            Rails.logger.error('PushNotificationManger: ' + error_data.to_s)
          end
        end
      elsif ticket_error.respond_to?(:explain)
        # We can destroy all tokens because the only case
        # it have explain method on ticket is when DeviceNotRegistered
        original_token = ticket_error.original_push_token
        next unless original_token

        ExpoPnSubscription.where(expo_pn_token: original_token).destroy_all
      else
        Rails.logger.error('PushNotificationManger: ' + ticket_error.to_s)
      end
    end

    # Only triggered when there is an ticket entry with error (whole request error)
    # Ticket error like DeviceNotRegistered won't trigger this
    retry_push_notification(tokens: opts[:tokens], push_notification_id: push_notification.id) if should_retry

    # handle ticket receipts
    ReceiptsManager.queue_receipts(tickets, push_notification)
  end

  def self.retry_push_notification(tokens:, push_notification_id:)
    # update all existing push_notification_retries
    PushNotificationRetry.where(push_notification_id: push_notification_id, token: tokens).update_all(
      ['retry_count = retry_count + 1, updated_at = ?', Time.current]
    )
    existing_push_notification_retries = PushNotificationRetry.where(push_notification_id: push_notification_id,
                                                                     token: tokens)

    # create non-existing push_notification_retries
    new_tokens = tokens - existing_push_notification_retries.map(&:token)
    new_push_notification_retries_input = new_tokens.map do |token|
      {
        token: token,
        push_notification_id: push_notification_id,
        retry_count: 1
      }
    end
    new_push_notification_retries = PushNotificationRetry.create(new_push_notification_retries_input)
    push_notification_retries = existing_push_notification_retries + new_push_notification_retries

    # filter push_notification_retries that have retry_count < RETRY_LIMIT
    eligible_retry_records = push_notification_retries.select do |retry_record|
      retry_record.eligible_to_retry
    end
    # group eligible_retry_records by retry_count
    eligible_retry_records_by_retry_count = eligible_retry_records.group_by(&:retry_count)
    # loop through eligible_retry_records_by_retry_count and enqueue
    eligible_retry_records_by_retry_count.each do |retry_count, retry_records|
      retry_ids = retry_records.map(&:id)
      Jobs.enqueue_in(
        PushNotificationRetry.calculate_retry_time(retry_count),
        :expo_push_notification,
        retry_ids: retry_ids
      )
    end

    # filter push_notification_retries that have retry_count >= RETRY_LIMIT and get the ids
    excessive_retry_ids = push_notification_retries.select do |retry_record|
      !retry_record.eligible_to_retry
    end.map(&:id)
    return unless excessive_retry_ids.present?

    # delete_all excessive_retry_ids
    PushNotificationRetry.where(id: excessive_retry_ids).delete_all
    # log excessive_retry_ids
    Rails.logger.error("PushNotificationManger: Excessive retries for push_notification_id: #{push_notification_id}")
  end

  def self.build_experience_id_groups(expo_pn_subscriptions)
    experience_id_group = Hash.new { |hash, key| hash[key] = [] }

    expo_pn_subscriptions.each do |expo_pn_subscription|
      expo_pn_token, experience_id =
        expo_pn_subscription.values_at(:expo_pn_token, :experience_id)

      experience_id_group[experience_id].push(expo_pn_token)
    end

    experience_id_group
  end
end
