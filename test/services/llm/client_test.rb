# frozen_string_literal: true

require "test_helper"

module LLM
  class ClientTest < ActiveSupport::TestCase
    # Include Rails time helpers
    include ActiveSupport::Testing::TimeHelpers

    setup do
      @client = Client.new

      # Create a test LLMRequest
      @llm_request = LLMRequest.new(
        prompt: "test prompt",
        llm_model_name: "claude-test-model", # Use a name matching a family
        request_type: "test"
      )

      # Use travel_to instead of direct stubbing to set a fixed time
      travel_to Time.new(2025, 3, 4, 12, 0, 0).utc

      # Clear cache for circuit breaker
      Rails.cache.clear
    end

    teardown do
      # Ensure time is reset after each test
      travel_back
    end

    test "generates response from LLM" do
      mock_response = { content: "test response" }
      mock_llm_client = mock("LLMClient")

      # Mock the retry handler to yield once
      mock_retry_handler = mock("RetryHandler")
      mock_retry_handler.expects(:with_retries).yields.returns(mock_response)
      RetryHandler.expects(:new).with(mock_llm_client).returns(mock_retry_handler)

      # Mock the client factory to expect the specific model name
      LLM::ClientFactory.expects(:create).with("claude-test-model", {}).returns(mock_llm_client)

      # The client should directly generate the response with the LLMRequest
      mock_llm_client.expects(:generate).with(@llm_request).returns(mock_response)

      # Mock the circuit breaker
      mock_circuit_breaker = mock("CircuitBreaker")
      mock_circuit_breaker.expects(:allow_request?).returns(true)
      mock_circuit_breaker.expects(:record_success)
      CircuitBreaker.expects(:new).returns(mock_circuit_breaker)

      response = @client.generate(@llm_request)
      assert_equal mock_response, response
    end

    test "checks circuit breaker before making request" do
      # Force circuit breaker to open
      circuit_breaker = LLM::CircuitBreaker.new("anthropic:#{@llm_request.llm_model_name}")
      LLM::CircuitBreaker::FAILURE_THRESHOLD.times do
        circuit_breaker.record_failure
      end

      # Should raise ServiceUnavailableError
      assert_raises(LLM::ServiceUnavailableError) do
        @client.generate(@llm_request)
      end
    end

    test "records success in circuit breaker" do
      # Mock the LLM client
      mock_llm_client = mock("LLMClient")
      mock_llm_client.expects(:generate).with(@llm_request).returns({ content: "Test response", metadata: {} })

      # Mock the client factory to expect the specific model name
      LLM::ClientFactory.expects(:create).with("claude-test-model", {}).returns(mock_llm_client)

      # Mock the retry handler
      mock_retry_handler = mock("RetryHandler")
      mock_retry_handler.expects(:with_retries).yields.returns({ content: "Test response", metadata: {} })
      RetryHandler.expects(:new).with(mock_llm_client).returns(mock_retry_handler)

      # Circuit should still be closed
      circuit_breaker = LLM::CircuitBreaker.new("anthropic:#{@llm_request.llm_model_name}")

      @client.generate(@llm_request)

      # Circuit should still be closed
      assert circuit_breaker.allow_request?
    end

    test "records failure in circuit breaker on error" do
      # Mock the circuit breaker - only expect allow_request? to be called
      mock_circuit_breaker = mock("CircuitBreaker")
      mock_circuit_breaker.expects(:allow_request?).returns(true)
      # We don't expect record_failure to be called in the client since it's handled in the RetryHandler
      CircuitBreaker.expects(:new).returns(mock_circuit_breaker)

      # Mock the client factory to expect the specific model name
      mock_llm_client = mock("LLMClient")
      LLM::ClientFactory.expects(:create).with("claude-test-model", {}).returns(mock_llm_client)

      # Mock the retry handler to raise an error
      mock_retry_handler = mock("RetryHandler")
      mock_retry_handler.expects(:with_retries).raises(LLM::AnthropicOverloadError.new)
      RetryHandler.expects(:new).with(mock_llm_client).returns(mock_retry_handler)

      # Should raise the error
      assert_raises(LLM::AnthropicOverloadError) do
        @client.generate(@llm_request)
      end
    end
  end
end
