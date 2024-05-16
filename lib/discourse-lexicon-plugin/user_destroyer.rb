# frozen_string_literal: true

# This code is copied from the Discourse codebase.
# It is extracted from the file 'app/services/user_destroyer.rb'.
# This code bypasses the check to see if the user can delete their account. By default, only admins can delete users. In this plugin, we want to bypass this check and allow users to delete their own accounts.
# Additionally, we have removed the code responsible for deleting posts because the primary focus of this plugin is to enable users to delete their accounts, and we assume that posts have already been deleted.

# Responsible for destroying a User record
module DiscourseLexiconPlugin
  class UserDestroyer
    class PostsExistError < RuntimeError
    end

    def initialize(actor)
      @actor = actor
      raise Discourse::InvalidParameters, 'acting user is nil' unless @actor && @actor.is_a?(User)

      @guardian = Guardian.new(actor)
    end

    # Returns false if the user failed to be deleted.
    # Returns a frozen instance of the User if the delete succeeded.
    def destroy(user, opts = {})
      raise Discourse::InvalidParameters, 'user is nil' unless user && user.is_a?(User)
      raise PostsExistError if user.posts.joins(:topic).count != 0

      # default to using a transaction
      opts[:transaction] = true if opts[:transaction] != false

      prepare_for_destroy(user) if opts[:prepare_for_destroy] == true

      result = nil

      optional_transaction(open_transaction: opts[:transaction]) do
        UserSecurityKey.where(user_id: user.id).delete_all
        Bookmark.where(user_id: user.id).delete_all
        Draft.where(user_id: user.id).delete_all
        Reviewable.where(created_by_id: user.id).delete_all

        user.post_actions.find_each { |post_action| post_action.remove_act!(Discourse.system_user) }

        # Add info about the user to staff action logs
        UserHistory.staff_action_records(
          Discourse.system_user,
          acting_user: user.username
        ).update_all(
          ['details = CONCAT(details, ?)', "\nuser_id: #{user.id}\nusername: #{user.username}"]
        )

        # keep track of emails used
        user_emails = user.user_emails.pluck(:email)

        if result = user.destroy
          Post.unscoped.where(user_id: result.id).update_all(user_id: nil)

          # If this user created categories, fix those up:
          Category
            .where(user_id: result.id)
            .each do |c|
              c.user_id = Discourse::SYSTEM_USER_ID
              c.save!
              next unless topic = Topic.unscoped.find_by(id: c.topic_id)

              topic.recover!
              topic.user_id = Discourse::SYSTEM_USER_ID
              topic.save!
            end

          Invite
            .where(email: user_emails)
            .each do |invite|
              # invited_users will be removed by dependent destroy association when user is destroyed
              invite.invited_groups.destroy_all
              invite.topic_invites.destroy_all
              invite.destroy
            end

          MessageBus.publish "/logout/#{result.id}", result.id, user_ids: [result.id]
        end
      end

      # After the user is deleted, remove the reviewable
      if reviewable = ReviewableUser.pending.find_by(target: user)
        reviewable.perform(@actor, :delete_user)
      end

      result
    end

    protected

    def prepare_for_destroy(user)
      PostAction.where(user_id: user.id).delete_all
      UserAction.where(
        'user_id = :user_id OR target_user_id = :user_id OR acting_user_id = :user_id',
        user_id: user.id
      ).delete_all
      PostTiming.where(user_id: user.id).delete_all
      TopicViewItem.where(user_id: user.id).delete_all
      TopicUser.where(user_id: user.id).delete_all
      TopicAllowedUser.where(user_id: user.id).delete_all
      Notification.where(user_id: user.id).delete_all
    end

    def optional_transaction(open_transaction: true, &block)
      if open_transaction
        User.transaction(&block)
      else
        yield
      end
    end
  end
end
