ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "omniauth"

module SignInHelper
  def sign_in_with_google
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "123456789",
      info: {
        email: "test@example.com",
        name: "Test User",
        image: "https://example.com/photo.jpg"
      },
      credentials: {
        token: "mock_access_token",
        expires_at: 1.hour.from_now.to_i
      }
    })
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
    visit "/auth/google_oauth2/callback"
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::SystemTestCase
  include SignInHelper
end
