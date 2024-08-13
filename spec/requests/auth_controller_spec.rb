# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Auth', type: :request do
  describe 'GET /auth/status' do
    it 'returns auth available status with with default settings' do
      get '/lexicon/auth/status.json'

      json_response = JSON.parse(response.body)
      expect(response.status).to eq(200)

      expect(json_response).to eq({ 'apple' => false, 'loginLink' => false })
    end
    context 'when auth status is true for apple' do
      before do
        SiteSetting.lexicon_apple_client_id = 'com.lexicon.app'
        SiteSetting.lexicon_apple_login_enabled = true
      end

      it 'returns auth available status with apple true' do
        get '/lexicon/auth/status.json'

        json_response = JSON.parse(response.body)
        expect(response.status).to eq(200)

        expect(json_response).to eq({ 'apple' => true, 'loginLink' => false })
      end
    end
    context 'when auth status is true for login link' do
      before do
        SiteSetting.lexicon_app_scheme = 'lexicon'
        SiteSetting.lexicon_login_link_enabled = true
      end

      it 'returns auth available status with login link true' do
        get '/lexicon/auth/status.json'

        json_response = JSON.parse(response.body)
        expect(response.status).to eq(200)

        expect(json_response).to eq({ 'apple' => false, 'loginLink' => true })
      end
    end
  end
end
