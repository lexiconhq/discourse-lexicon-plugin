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

      PushNotificationCleanup.new(user).delete_lexicon_plugin_data

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
  end
end