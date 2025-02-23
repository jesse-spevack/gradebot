if Rails.env.test?
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

  # Disable request forgery protection in test environment
  OmniAuth.config.before_callback_phase do |env|
    env["action_dispatch.request.parameters"] = {}
  end
end
