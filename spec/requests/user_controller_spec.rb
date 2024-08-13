# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User', type: :request do
  fab!(:user) { Fabricate(:user) }
  describe 'GET auth/user' do
    it 'return empty data before login' do
      get '/lexicon/auth/user.json'
      json_response = JSON.parse(response.body)
      expect(response.status).to eq(200)

      expect(json_response).to eq(nil)
    end

    context 'while logged in' do
      before do
        sign_in(user)
      end
      it 'should return data user' do
        get '/lexicon/auth/user.json'

        json_response = JSON.parse(response.body)
        expect(response.status).to eq(200)

        expect(json_response['user']['username']).not_to be_empty
        expect(json_response['user']['username']).to eq(user['username'])
        expect(json_response['user']['name']).not_to be_empty
        expect(json_response['user']['avatar_template']).not_to be_empty
      end
    end
  end
end
