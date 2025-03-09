# frozen_string_literal: true

require "test_helper"

module LLM
  class ClientTest < ActiveSupport::TestCase
    # Include Rails time helpers
    include ActiveSupport::Testing::TimeHelpers

    setup do
      @client = Client.new

      # Stub SecureRandom.uuid to return a consistent value for testing
      SecureRandom.stubs(:uuid).returns("test-uuid")

      # Create a test LLMRequest
      @llm_request = LLMRequest.new(
        prompt: "test prompt",
        llm_model_name: "test-model",
        request_type: "test"
      )

      # Use travel_to instead of direct stubbing to set a fixed time
      travel_to Time.new(2025, 3, 4, 12, 0, 0).utc
    end

    teardown do
      # Ensure time is reset after each test
      travel_back
    end

    test "generates response from LLM" do
      mock_response = { content: "test response" }

      # We directly mock the client factory without expecting the decorator
      LLM::ClientFactory.expects(:create).returns(mock_client)

      # The client should directly generate the response with the LLMRequest
      mock_client.expects(:generate).with(@llm_request).returns(mock_response)

      response = @client.generate(@llm_request)
      assert_equal mock_response, response
    end

    private

    def mock_client
      @mock_client ||= mock("LLMClient")
    end
  end
end
