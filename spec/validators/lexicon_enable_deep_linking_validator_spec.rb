# frozen_string_literal: true

require "rails_helper"

describe LexiconEnableDeepLinkingValidator do
  it "always returns false if setting the value to true but app scheme is empty" do
    validator = described_class.new

    expect(validator.valid_value?("t")).to eq(false)
    expect(validator.error_message).to eq(
      I18n.t("site_settings.errors.missing_app_scheme"),
    )
  end

  context "when app scheme is present" do
    before do
      SiteSetting.lexicon_app_scheme = "lexicon"
    end

    it "allows email deep linking to be enabled for a valid scheme" do
      validator = described_class.new
      
      expect(validator.valid_value?("t")).to eq(true)
    end
  end
end
  