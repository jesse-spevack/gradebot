# frozen_string_literal: true

# Helper methods for testing LLM components
module LLMTestHelper
  # Stub the Anthropic API key for testing
  #
  # @param client [LLM::Anthropic::Client] The client instance to set the API key for
  # @return [String] The test API key
  def stub_anthropic_api_key(client = nil)
    test_key = "test-anthropic-key-#{SecureRandom.hex(4)}"

    # If a client instance is provided, set its API key directly
    client.api_key = test_key if client

    # Stub the fetch_api_key method for any new instances
    LLM::Anthropic::Client.any_instance.stubs(:fetch_api_key).returns(test_key)

    test_key
  end

  # Unstub the Anthropic API key after testing
  def unstub_anthropic_api_key
    LLM::Anthropic::Client.any_instance.unstub(:fetch_api_key)
  end
end
