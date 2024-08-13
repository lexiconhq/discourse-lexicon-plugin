# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Expo Push Notifications', type: :request do
  fab!(:user) { Fabricate(:user) }
  push_notifications_token = 'random_token'
  application_name = 'test-app'
  platform = 'android'
  experience_id = '@test/test-app'

  describe 'Post push_notifications/subscribe' do
    params = { push_notifications_token: push_notifications_token, application_name: application_name,
               platform: platform, experience_id: experience_id }

    before do
      sign_in(user)
    end
    it 'should success add token and return {expo_pn_token, user_id}' do
      post '/lexicon/push_notifications/subscribe.json', params: params

      json_response = JSON.parse(response.body)
      expect(response.status).to eq(200)
      expect(json_response['expo_pn_token']).to eq(params[:push_notifications_token])
      expect(json_response['user_id']).to eq(user[:id])
    end

    it 'should return invalid param' do
      post '/lexicon/push_notifications/subscribe.json'

      json_response = JSON.parse(response.body)
      expect(response.status).to eq(400)
      expect(json_response['errors']).to include('param is missing or the value is empty: push_notifications_token')
    end

    it 'should return invalid platform' do
      params[:platform] = 'invalid platform'

      post '/lexicon/push_notifications/subscribe.json', params: params

      json_response = JSON.parse(response.body)
      expect(response.status).to eq(400)
      expect(json_response['errors']).to include('You supplied invalid parameters to the request: "platform" must be "ios" or "android".')
    end
  end

  describe 'Post push_notifications/delete_subscribe' do
    before do
      sign_in(user)
    end
    it 'should return invalid param' do
      post '/lexicon/push_notifications/delete_subscribe.json'

      json_response = JSON.parse(response.body)
      expect(response.status).to eq(400)
      expect(json_response['errors']).to include('param is missing or the value is empty: push_notifications_token')
    end

    it 'should return login user' do
      post '/lexicon/push_notifications/delete_subscribe.json',
           params: { push_notifications_token: push_notifications_token }

      json_response = JSON.parse(response.body)
      expect(response.status).to eq(200)
      expect(json_response).to eq({ 'message' => 'success' })
    end
  end
end
