# frozen_string_literal: true

require 'rails_helper'
require_relative '../test_helper'

describe LexiconAppleClientIdValidator do
  it 'always returns true if apple client id is in the correct format and length' do
    validator = described_class.new
    expect(validator.valid_value?('com.lexicon.app')).to eq(true)
    expect(validator.valid_value?('123.lexicon.app')).to eq(true)
  end

  context 'always return false if the apple client id format incorrect' do
    it "contains symbols other than plus ('+'), period ('.'), or hyphen ('-')" do
      validator = described_class.new

      expect(validator.valid_value?('com.lexicon.app()')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.wrong_format_apple_client_id')
      )

      expect(validator.valid_value?('com.lexicon.data//.3')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.wrong_format_apple_client_id')
      )
    end

    it 'is less than 10 characters or greater than 155 characters' do
      validator = described_class.new

      expect(validator.valid_value?('com')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.min_apple_client_id_length')
      )

      random_string = generate_random_string(156)
      expect(validator.valid_value?(random_string)).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.max_apple_client_id_length')
      )
    end
  end

  context 'when apple login is already enabled' do
    before do
      SiteSetting.lexicon_apple_client_id = 'com.lexicon.app'
      SiteSetting.lexicon_apple_login_enabled = true
    end

    it 'does not allow apple client id to be blank' do
      validator = described_class.new

      expect(validator.valid_value?('')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.missing_apple_client_id')
      )
    end
  end
end
