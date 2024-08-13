# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activate Account', type: :request do
  describe 'POST auth/activate_account' do
    let(:user) { Fabricate(:user) }
    let(:email_token) { Fabricate(:email_token, user: user) }

    # A honeypot is a security mechanism that creates a virtual trap to lure attackers.
    it 'returns error invalid access without honeypot' do
      post '/lexicon/auth/activate_account.json'

      json_response = JSON.parse(response.body)
      expect(response.status).to eq(403)

      expect(json_response).to include({ 'error_type' => 'invalid_access' })
    end

    context 'with valid token' do
      it 'raises an error if the honeypot is invalid' do
        DiscourseLexiconPlugin::ActivateAccountController.any_instance.stubs(:honeypot_or_challenge_fails?).returns(true)
        post '/lexicon/auth/activate_account.json'

        expect(response.status).to eq(403)
      end

      context 'with honeypot' do
        before do
          DiscourseLexiconPlugin::ActivateAccountController.any_instance.stubs(:honeypot_or_challenge_fails?).returns(false)
        end

        it 'correctly logs on user' do
          user.update(active: true)
          post '/lexicon/auth/activate_account.json', params: { token: email_token.token }

          json_response = JSON.parse(response.body)

          expect(response.status).to eq(200)
          expect(json_response['user']['username']).not_to be_empty
          expect(json_response['user']['name']).not_to be_empty
          expect(json_response['user']['avatar_template']).not_to be_empty
          expect(session[:current_user_id]).to be_present
          expect(response.headers['set-cookie']).to include('_t=')
        end

        context 'when user is not approved' do
          before { SiteSetting.must_approve_users = true }

          it 'should return the right response' do
            post '/lexicon/auth/activate_account.json', params: { token: email_token.token }

            json_response = JSON.parse(response.body)

            expect(response.status).to eq(200)

            expect(json_response).to eq('error' => 'need approval from moderator')
            expect(session[:current_user_id]).to be_blank
          end
        end
      end
    end
  end
end
