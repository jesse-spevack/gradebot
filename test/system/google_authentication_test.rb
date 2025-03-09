require "test_helper"
require "application_system_test_case"

class GoogleAuthenticationTest < ApplicationSystemTestCase
  def setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "123456789",
      info: {
        email: "test@example.com",
        name: "Test User",
        image: "https://example.com/photo.jpg"
      },
      credentials: {
        token: "mock_token",
        refresh_token: "mock_refresh_token",
        expires_at: 1.hour.from_now.to_i,
        scope: "https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/documents"
      }
    })
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  test "authentication flow" do
    visit new_session_path
    visit "/auth/google_oauth2/callback"
    assert_current_path new_grading_task_path

    # Verify user data
    user = User.last
    assert_equal "test@example.com", user.email
    assert_equal "Test User", user.name

    # Sign out - specifically using the header button, not the sidebar one
    find("header a", text: "Sign out").click
    assert_current_path root_path
  end

  test "OAuth scopes" do
    mock_auth = OmniAuth.config.mock_auth[:google_oauth2]
    required_scopes = [
      "https://www.googleapis.com/auth/drive",
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/documents"
    ]
    required_scopes.each do |scope|
      assert_includes mock_auth.credentials.scope, scope
    end
  end
end
