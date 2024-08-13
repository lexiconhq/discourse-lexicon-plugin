# frozen_string_literal: true

require 'rails_helper'

describe LexiconEnableAppleLoginValidator do
  it 'always returns false if setting the value to true but apple client id is empty' do
    validator = described_class.new

    expect(validator.valid_value?('t')).to eq(false)
    expect(validator.error_message).to eq(
      I18n.t('site_settings.errors.missing_apple_client_id')
    )
  end

  context 'when apple client id is present' do
    before do
      SiteSetting.lexicon_apple_client_id = 'com.lexicon'
    end

    it 'allows apple login to be enabled for a valid apple client id' do
      validator = described_class.new

      expect(validator.valid_value?('t')).to eq(true)
    end
  end
end
