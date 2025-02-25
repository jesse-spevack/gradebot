ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "omniauth"

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

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
  include AuthenticationHelper

  def before_setup
    super
    OmniAuth.config.test_mode = true
  end

  def after_teardown
    super
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
