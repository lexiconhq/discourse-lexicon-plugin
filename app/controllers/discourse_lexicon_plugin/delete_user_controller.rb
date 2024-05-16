# frozen_string_literal: true

module DiscourseLexiconPlugin
  class DeleteUserController < ::ApplicationController
    requires_plugin DiscourseLexiconPlugin

    def delete
      password = params.require(:password)
      user = current_user
      return render json: { error: 'user not found' } unless user.present?
      return render json: { error: 'an admin cannot delete its own account.' } if user.admin?
      return render json: { error: 'wrong password' } unless user.confirm_password?(password)

      delete_posts(user)

      delete_lexicon_plugin_data(user)

      delete_account(user)

      render json: { message: 'success' }
    end

    private

    def delete_posts(user, batch_size = 20)
      Reviewable.where(created_by_id: user.id).delete_all

      user.posts
          .order('post_number desc')
          .limit(batch_size)
          .each { |p| PostDestroyerAll.new(user, p).destroy }
    end

    def delete_account(user)
      DiscourseLexiconPlugin::UserDestroyer.new(user).destroy(user)
    end

    def delete_lexicon_plugin_data(user)
      push_notifications_ids = get_push_notifications_ids_by_user(user)

      delete_push_notifications_receipt(push_notifications_ids)
      delete_push_notifications_retry(push_notifications_ids)
      delete_push_notifications(push_notifications_ids)
    end

    # Delete all data push notifications of deleted user
    def delete_push_notifications(ids)
      PushNotification
        .where(id: ids)
        .delete_all
    end

    def delete_push_notifications_retry(ids)
      PushNotificationRetry
        .where(push_notification_id: ids)
        .delete_all
    end

    def delete_push_notifications_receipt(ids)
      PushNotificationReceipt
        .where(push_notification_id: ids)
        .delete_all
    end

    def get_push_notifications_ids_by_user(user)
      PushNotification
        .where(user_id: user.id)
        .pluck(:id)
    end
  end
end
