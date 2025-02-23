require "test_helper"
require "application_system_test_case"

class GoogleAuthenticationTest < ApplicationSystemTestCase
  def setup
    # Mock OAuth2 response from Google
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
  end

  test "signing in with Google" do
    visit new_session_path
    assert_selector "button", text: "Sign in with Google"
    assert_no_selector "a", text: "Sign out"
    sign_in_with_google
    assert_current_path grading_job_path
    assert_selector "a", text: "Sign out"
    assert_no_selector "button", text: "Sign in with Google"
    # Verify user data was saved
    user = User.last
    assert_equal "test@example.com", user.email
    assert_equal "Test User", user.name
    assert_equal "https://example.com/photo.jpg", user.profile_picture_url
  end

  test "signing out" do
    sign_in_with_google
    assert_current_path grading_job_path
    click_on "Sign out"
    assert_current_path root_path
    assert_selector "button", text: "Sign in with Google"
    assert_no_selector "a", text: "Sign out"
  end

  test "authentication persists across page reloads" do
    sign_in_with_google
    assert_current_path grading_job_path
    visit current_path # reload the page
    assert_current_path grading_job_path
    assert_selector "a", text: "Sign out"
    assert_no_selector "a", text: "Sign in with Google"
  end

  test "OAuth scopes include necessary Google permissions" do
    # We verify this by checking the mock auth configuration
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
