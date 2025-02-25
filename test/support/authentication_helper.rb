module AuthenticationHelper
  def login_as(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: user.google_uid,
      info: {
        email: user.email,
        name: user.name,
        image: user.profile_picture_url
      },
      credentials: {
        token: "mock_token",
        refresh_token: "mock_refresh_token",
        expires_at: 1.hour.from_now.to_i
      }
    })

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
    visit "/auth/google_oauth2/callback"
  end
end
