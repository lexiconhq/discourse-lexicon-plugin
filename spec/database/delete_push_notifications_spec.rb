# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Database operations', type: :model do
  describe 'Delete Session and Token' do
    it 'deletes a session and its connected token' do
      session = UserAuthToken.create(
        user_id: '-1',
        user_agent: nil,
        client_ip: '33322',
        auth_token: 'testhashtoken',
        prev_auth_token: 'prevToken',
        rotated_at: Time.zone.now
      )
      ExpoPnSubscription.create!(
        user_id: -1,
        expo_pn_token: 'testToken',
        experience_id: 'test-experience-id',
        application_name: 'test',
        platform: 'ios',
        user_auth_token_id: session.id
      )
      expect do
        session.destroy
      end.to change { ExpoPnSubscription.count }.by(-1).and change { UserAuthToken.count }.by(-1)
    end
  end
end
