require "application_system_test_case"

class PrivacyTest < ApplicationSystemTestCase
  test "visiting the privacy policy page" do
    # The privacy policy should be accessible without authentication
    visit privacy_path

    assert_selector "h1", text: "Privacy Policy"
    assert_text "Your privacy is important to us"
  end
end
