ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "omniauth"
require_relative "../lib/base_command"
require "mocha/minitest"
require "active_support/testing/parallelization"
require "minitest/autorun"

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

# Define test helpers before including them
module LLMTestHelpers
  def stub_llm_request(content:, request_type: nil)
    LLM::Client.any_instance.stubs(:generate).returns({
      content: content,
      finish_reason: "stop",
      model: "claude-3-5-haiku",
      response_id: "test-response-id"
    })
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Include the LLM configuration helper for all tests
    include LLMConfigurationHelper

    include LLMTestHelpers
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
