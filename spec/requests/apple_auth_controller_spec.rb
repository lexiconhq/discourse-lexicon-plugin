# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apple Auth', type: :request do
  describe 'POST auth/apple/login' do
    it 'returns error feature not enable' do
      post '/lexicon/auth/apple/login.json'

      json_response = JSON.parse(response.body)
      expect(response.status).to eq(200)

      expect(json_response).to eq({ 'error' => 'Apple authentication feature is not enabled' })
    end
    context 'when Apple authentication feature is enabled' do
      let(:jwk) { ::JWT::JWK.new(OpenSSL::PKey::RSA.generate(1024)) }
      before do
        Discourse.cache.delete('sign-in-with-apple-jwks')
        SiteSetting.lexicon_apple_client_id = 'com.lexicon.app'
        SiteSetting.lexicon_apple_login_enabled = true
        EmailToken.where(email: 'no_email').update(confirmed: true)

        stub_request(:get, 'https://appleid.apple.com/auth/keys').to_return(
          body: { keys: [jwk.export] }.to_json
        )
      end

      it 'returns error when Apple Token is not provided' do
        post '/lexicon/auth/apple/login.json'

        json_response = JSON.parse(response.body)
        expect(response.status).to eq(400)
        expect(json_response).to eq({ 'errors' => ['param is missing or the value is empty: id_token'] })
      end

      it 'returns error when Apple Token is not valid' do
        post '/lexicon/auth/apple/login.json', params: { id_token: 'invalid_token' }

        json_response = JSON.parse(response.body)
        expect(response.status).to eq(200)
        expect(json_response).to eq({ 'error' => 'Apple Token Not Valid' })
      end

      it 'returns email not found' do
        valid_token = JWT.encode(
          { email: 'verified-email@example.com', iss: 'https://appleid.apple.com',
            aud: 'com.lexicon.app' }, jwk.keypair, 'RS256', { kid: jwk.kid }
        )
        post '/lexicon/auth/apple/login.json', params: { id_token: valid_token }

        json_response = JSON.parse(response.body)
        expect(response.status).to eq(200)
        expect(json_response).to eq({ 'error' => 'Email not found' })
      end

      it 'returns cookie with valid email and token' do
        valid_token = JWT.encode({ email: 'no_email', iss: 'https://appleid.apple.com', aud: 'com.lexicon.app' },
                                 jwk.keypair, 'RS256', { kid: jwk.kid })
        post '/lexicon/auth/apple/login.json', params: { id_token: valid_token }

        expect(response.status).to eq(200)
        expect(session[:current_user_id]).to eq(-1)
        expect(response.headers['set-cookie']).to include('_t=')
      end
    end
  end
end
