# frozen_string_literal: true

require 'rails_helper'
require_relative '../test_helper'

describe LexiconAppSchemeValidator do
  it 'always returns true if app scheme is in the correct format and length' do
    validator = described_class.new
    expect(validator.valid_value?('lexicon')).to eq(true)
  end

  context 'always return false if the app scheme' do
    it 'starts with a number or symbol' do
      validator = described_class.new

      expect(validator.valid_value?('1test')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.wrong_format_app_scheme')
      )

      expect(validator.valid_value?('+test')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.wrong_format_app_scheme')
      )
    end

    it "contains symbols other than plus ('+'), period ('.'), or hyphen ('-')" do
      validator = described_class.new

      expect(validator.valid_value?('test://')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.wrong_format_app_scheme')
      )

      expect(validator.valid_value?('test-12_34')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.wrong_format_app_scheme')
      )
    end

    it 'is less than 3 characters or greater than 2000 characters' do
      validator = described_class.new

      expect(validator.valid_value?('te')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.min_app_scheme_length')
      )

      random_string = generate_random_string(2001)
      expect(validator.valid_value?(random_string)).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.max_app_scheme_length')
      )
    end
  end

  context 'when email deep linking is already enabled' do
    before do
      SiteSetting.lexicon_app_scheme = 'lexicon'
      SiteSetting.lexicon_email_deep_linking_enabled = true
    end

    it 'does not allow app scheme to be blank' do
      validator = described_class.new

      expect(validator.valid_value?('')).to eq(false)
      expect(validator.error_message).to eq(
        I18n.t('site_settings.errors.missing_app_scheme')
      )
    end
  end
end
