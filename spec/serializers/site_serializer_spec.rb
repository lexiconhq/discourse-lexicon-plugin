# frozen_string_literal: true

require 'rails_helper'

describe SiteSerializer do
  let(:guardian) do
    Guardian.new
  end

  let(:serializer) do
    described_class.new(Site.new(guardian), scope: guardian, root: false)
  end

  default_settings = {
    lexicon_push_notifications_enabled: false,
    lexicon_email_deep_linking_enabled: false,
    lexicon_app_scheme: nil
  }

  enabled_settings = {
    lexicon_push_notifications_enabled: true,
    lexicon_email_deep_linking_enabled: true,
    lexicon_app_scheme: 'kflounge'
  }

  describe 'includes lexicon settings in site.json' do
    it 'renders correctly with all settings enabled / set' do
      SiteSetting.lexicon_app_scheme = enabled_settings[:lexicon_app_scheme]
      SiteSetting.lexicon_push_notifications_enabled = enabled_settings[:lexicon_push_notifications_enabled]
      SiteSetting.lexicon_email_deep_linking_enabled = enabled_settings[:lexicon_email_deep_linking_enabled]
      expected = { settings: enabled_settings }
      expect(serializer.as_json[:lexicon]).to eq(expected)
    end

    describe 'lexicon_app_scheme: nil' do
      it 'renders lexicon_app_scheme as nil when set to nil' do
        SiteSetting.lexicon_app_scheme = nil
        expected = { settings: default_settings }
        expect(serializer.as_json[:lexicon]).to eq(expected)
      end
      it 'renders lexicon_app_scheme as nil when set to an empty string' do
        SiteSetting.lexicon_app_scheme = ''
        expected = { settings: default_settings }
        expect(serializer.as_json[:lexicon]).to eq(expected)
      end
    end
  end
end
