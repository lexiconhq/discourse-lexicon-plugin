# frozen_string_literal: true

# This code is copied from the Discourse codebase.
# It is extracted from the file 'lib/post_destroyer.rb'.
# This code bypasses the check to determine whether the post is being deleted by an admin or a user. In this case, we do not want to differentiate between an admin or a user deleting the post.

#
# How a post is deleted is affected by who is performing the action.
# this class contains the logic to delete it.
#
module DiscourseLexiconPlugin
  class PostDestroyer
    def initialize(user, post, opts = {})
      @user = user
      @post = post
      @topic = post.topic || Topic.with_deleted.find_by(id: @post.topic_id)
      @opts = opts
    end

    def destroy
      payload = WebHook.generate_payload(:post, @post) if WebHook.active_web_hooks(:post).exists?
      is_first_post = @post.is_first_post? && @topic
      has_topic_web_hooks = is_first_post && WebHook.active_web_hooks(:topic).exists?

      if has_topic_web_hooks
        topic_view = TopicView.new(@topic.id, Discourse.system_user, skip_staff_action: true)
        topic_payload = WebHook.generate_payload(:topic, topic_view, WebHookTopicViewSerializer)
      end

      perform_delete

      UserActionManager.post_destroyed(@post)

      DiscourseEvent.trigger(:post_destroyed, @post, @opts, @user)
      WebHook.enqueue_post_hooks(:post_destroyed, @post, payload)
      Jobs.enqueue(:sync_topic_user_bookmarked, topic_id: @topic.id) if @topic

      return unless is_first_post

      UserProfile.remove_featured_topic_from_all_profiles(@topic)
      UserActionManager.topic_destroyed(@topic)
      DiscourseEvent.trigger(:topic_destroyed, @topic, @user)
      WebHook.enqueue_topic_hooks(:topic_destroyed, @topic, topic_payload) if has_topic_web_hooks
      return unless SiteSetting.tos_topic_id == @topic.id || SiteSetting.privacy_topic_id == @topic.id

      Discourse.clear_urls!
    end

    # When a post is properly deleted. Well, it's still soft deleted, but it will no longer
    # show up in the topic
    def perform_delete
      Post.transaction do
        @post.trash!(@user)
        if @post.topic
          make_previous_post_the_last_one
          mark_topic_changed
          clear_user_posted_flag
        end

        Topic.reset_highest(@post.topic_id)
        trash_public_post_actions
        trash_user_actions
        remove_associated_replies
        remove_associated_notifications

        if @user.id != @post.user_id && !@opts[:skip_staff_log]
          if @post.topic && @post.is_first_post?
            StaffActionLogger.new(@user).log_topic_delete_recover(
              @post.topic,
              'delete_topic',
              @opts.slice(:context)
            )
          else
            StaffActionLogger.new(@user).log_post_deletion(@post, @opts.slice(:context))
          end
        end

        if @topic && @post.is_first_post?
          @topic.trash!(@user)
          PublishedPage.unpublish!(@user, @topic) if @topic.published_page
        end

        TopicLink.where(link_post_id: @post.id).destroy_all
        update_associated_category_latest_topic
        update_user_counts
        TopicUser.update_post_action_cache(post_id: @post.id)

        DB.after_commit do
          if @opts[:reviewable]
            notify_deletion(
              @opts[:reviewable],
              { notify_responders: @opts[:notify_responders], parent_post: @opts[:parent_post] }
            )
            if @post.reviewable_flag &&
               SiteSetting.notify_users_after_responses_deleted_on_flagged_post
              ignore(@post.reviewable_flag)
            end
          elsif reviewable = @post.reviewable_flag
            @opts[:defer_flags] ? ignore(reviewable) : agree(reviewable)
          end
        end
      end

      update_imap_sync(@post, true) if @post.topic&.deleted_at
      feature_users_in_the_topic if @post.topic
      @post.publish_change_to_clients!(:deleted) if @post.topic
      return unless @post.topic && @post.post_number == 1

      TopicTrackingState.send(:publish_delete, @post.topic)
    end

    private

    # we need topics to change if ever a post in them is deleted or created
    # this ensures users relying on this information can keep unread tracking
    # working as desired
    def mark_topic_changed
      # make this as fast as possible, can bypass everything
      DB.exec(<<~SQL, updated_at: Time.now, id: @post.topic_id)
        UPDATE topics
        SET updated_at = :updated_at
        WHERE id = :id
      SQL
    end

    def make_previous_post_the_last_one
      last_post =
        Post
        .select(:created_at, :user_id, :post_number)
        .where('topic_id = ? and id <> ?', @post.topic_id, @post.id)
        .where.not(user_id: nil)
        .where.not(post_type: Post.types[:whisper])
        .order('created_at desc')
        .first

      return unless last_post.present?

      topic = @post.topic
      topic.last_posted_at = last_post.created_at
      topic.last_post_user_id = last_post.user_id
      topic.highest_post_number = last_post.post_number

      # we go via save here cause we need to run hooks
      topic.save!(validate: false)
    end

    def clear_user_posted_flag
      unless Post.exists?(
        ['topic_id = ? and user_id = ? and id <> ?', @post.topic_id, @post.user_id, @post.id]
      )
        TopicUser.where(topic_id: @post.topic_id, user_id: @post.user_id).update_all 'posted = false'
      end
    end

    def feature_users_in_the_topic
      Jobs.enqueue(:feature_topic_users, topic_id: @post.topic_id)
    end

    def trash_public_post_actions
      return unless public_post_actions = PostAction.publics.where(post_id: @post.id)

      public_post_actions.each { |pa| pa.trash!(@user) }

      @post.custom_fields['deleted_public_actions'] = public_post_actions.ids
      @post.save_custom_fields

      f = PostActionType.public_types.map { |k, _| ["#{k}_count", 0] }
      Post.with_deleted.where(id: @post.id).update_all(Hash[*f.flatten])
    end

    def agree(reviewable)
      notify_deletion(reviewable)
      result = reviewable.perform(@user, :agree_and_keep, post_was_deleted: true)
      reviewable.transition_to(result.transition_to, @user)
    end

    def ignore(reviewable)
      reviewable.perform_ignore_and_do_nothing(@user, post_was_deleted: true)
      reviewable.transition_to(:ignored, @user)
    end

    def notify_deletion(reviewable, options = {})
      return if @post.user.blank?

      allowed_user = @user.human? && @user.staff?
      return unless allowed_user && rs = reviewable.reviewable_scores.order('created_at DESC').first

      # ReviewableScore#types is a superset of PostActionType#flag_types.
      # If the reviewable score type is not on the latter, it means it's not a flag by a user and
      #  must be an automated flag like `needs_approval`. There's no flag reason for these kind of types.
      flag_type = PostActionType.flag_types[rs.reviewable_score_type]
      return unless flag_type

      notify_responders = options[:notify_responders]

      Jobs.enqueue(
        :send_system_message,
        user_id: @post.user_id,
        message_type:
          (
            if notify_responders
              'flags_agreed_and_post_deleted_for_responders'
            else
              'flags_agreed_and_post_deleted'
            end
          ),
        message_options: {
          flagged_post_raw_content: notify_responders ? options[:parent_post].raw : @post.raw,
          flagged_post_response_raw_content: @post.raw,
          url: notify_responders ? options[:parent_post].url : @post.url,
          flag_reason:
            I18n.t(
              "flag_reasons#{'.responder' if notify_responders}.#{flag_type}",
              locale: SiteSetting.default_locale,
              base_path: Discourse.base_path
            )
        }
      )
    end

    def trash_user_actions
      UserAction
        .where(target_post_id: @post.id)
        .each do |ua|
          row = {
            action_type: ua.action_type,
            user_id: ua.user_id,
            acting_user_id: ua.acting_user_id,
            target_topic_id: ua.target_topic_id,
            target_post_id: ua.target_post_id
          }
          UserAction.remove_action!(row)
        end
    end

    def remove_associated_replies
      post_ids = PostReply.where(reply_post_id: @post.id).pluck(:post_id)

      return unless post_ids.present?

      PostReply.where(reply_post_id: @post.id).delete_all
      Post.where(id: post_ids).each { |p| p.update_column :reply_count, p.replies.count }
    end

    def remove_associated_notifications
      Notification.where(topic_id: @post.topic_id, post_number: @post.post_number).delete_all
    end

    def update_associated_category_latest_topic
      return unless @post.topic && @post.topic.category
      if @post.id != @post.topic.category.latest_post_id &&
         !(@post.is_first_post? && @post.topic_id == @post.topic.category.latest_topic_id)
        return
      end

      @post.topic.category.update_latest
    end

    def update_user_counts
      author = @post.user

      return unless author

      author.create_user_stat if author.user_stat.nil?

      if @post.created_at == author.user_stat.first_post_created_at
        author.user_stat.update!(
          first_post_created_at: author.posts.order('created_at ASC').first.try(:created_at)
        )
      end

      UserStatCountUpdater.decrement!(@post)

      if @post.created_at == author.last_posted_at
        author.update_column(
          :last_posted_at,
          author.posts.order('created_at DESC').first.try(:created_at)
        )
      end

      return unless @post.is_first_post? && @post.topic && !@post.topic.private_message?

      # Update stats of all people who replied
      update_post_counts(:decrement)
    end

    def update_imap_sync(post, sync)
      return unless SiteSetting.enable_imap

      incoming = IncomingEmail.find_by(post_id: post.id, topic_id: post.topic_id)
      return if !incoming || !incoming.imap_uid

      incoming.update(imap_sync: sync)
    end

    def update_post_counts(operator)
      counts =
        Post
        .where(post_type: Post.types[:regular], topic_id: @post.topic_id)
        .where('post_number > 1')
        .group(:user_id)
        .count

      counts.each do |user_id, count|
        if user_stat = UserStat.where(user_id: user_id).first
          if operator == :decrement
            UserStatCountUpdater.set!(
              user_stat: user_stat,
              count: user_stat.post_count - count,
              count_column: :post_count
            )
          else
            UserStatCountUpdater.set!(
              user_stat: user_stat,
              count: user_stat.post_count + count,
              count_column: :post_count
            )
          end
        end
      end
    end
  end
end
