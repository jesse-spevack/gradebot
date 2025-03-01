# frozen_string_literal: true

require "test_helper"

class LLM::Anthropic::ClientTest < ActiveSupport::TestCase
  include LLMTestHelper

  setup do
    # Stub the API key instead of manipulating ENV
    stub_anthropic_api_key

    # Create client instance with test model
    @client = LLM::Anthropic::Client.new("claude-3-5-sonnet", max_tokens: 500, temperature: 0.5)

    # Mock HTTP for all tests
    @mock_response = mock("response")
    @mock_http = mock("http")
    Net::HTTP.stubs(:new).returns(@mock_http)
    @mock_http.stubs(:use_ssl=)
  end

  teardown do
    # Unstub the API key
    unstub_anthropic_api_key

    # Clean up stubs
    Net::HTTP.unstub(:new)
  end

  test "initializes with model name and options" do
    client = LLM::Anthropic::Client.new("claude-3-5-sonnet", max_tokens: 300, temperature: 0.8)

    assert_equal "claude-3-5-sonnet", client.model_name
    assert_equal 300, client.max_tokens
    assert_equal 0.8, client.temperature
    assert client.api_key.present?
    assert_match(/test-anthropic-key/, client.api_key)
  end

  test "uses default options when not specified" do
    client = LLM::Anthropic::Client.new("claude-3-5-sonnet")

    assert_equal LLM::Anthropic::Client::DEFAULT_MAX_TOKENS, client.max_tokens
    assert_equal 0.7, client.temperature
  end

  test "accepts custom API key in options" do
    custom_key = "custom-api-key"
    client = LLM::Anthropic::Client.new("claude-3-5-sonnet", api_key: custom_key)

    assert_equal custom_key, client.api_key
  end

  test "execute_request calls API and returns formatted response" do
    # Setup mock HTTP response
    @mock_response.stubs(:code).returns("200")
    @mock_response.stubs(:body).returns({
      id: "msg_123",
      content: [ { type: "text", text: "This is a test response" } ],
      usage: { input_tokens: 10, output_tokens: 15 }
    }.to_json)
    @mock_http.expects(:request).returns(@mock_response)

    # Execute request
    response = @client.execute_request(prompt: "Test prompt")

    # Verify response structure
    assert_equal "This is a test response", response[:content]
    assert_equal 10, response[:metadata][:tokens][:prompt]
    assert_equal 15, response[:metadata][:tokens][:completion]
    assert_equal 25, response[:metadata][:tokens][:total]
    assert_equal "claude-3-5-sonnet", response[:metadata][:model]
  end

  test "execute_request handles API error responses" do
    # Setup mock HTTP error response
    @mock_response.stubs(:code).returns("400")
    @mock_response.stubs(:body).returns({
      error: { message: "Invalid request parameters" }
    }.to_json)
    @mock_http.expects(:request).returns(@mock_response)

    # Execute request and expect error
    error = assert_raises(RuntimeError) do
      @client.execute_request(prompt: "Test prompt")
    end

    assert_match(/Anthropic API error/, error.message)
  end

  test "calculate_token_count returns an estimate based on text length" do
    # Test with different string lengths
    # Note: Implementation uses (length / 4.0).ceil for calculation
    assert_equal 4, @client.calculate_token_count(prompt: "This is a test")

    # For the longer text, let's calculate the expected token count
    longer_text = "This is a longer test with multiple words to estimate token count correctly"
    expected_tokens = (longer_text.length / 4.0).ceil
    assert_equal expected_tokens, @client.calculate_token_count(prompt: longer_text)
  end

  test "calculate_cost_estimate uses model-specific pricing" do
    # Test with Claude 3.5 Sonnet pricing
    # Note: The model will be resolved to claude-3-5-sonnet-20241022
    cost = @client.calculate_cost_estimate(1_000_000)

    # Expected cost calculation:
    # - 300,000 input tokens at $8 per million = $2.40
    # - 700,000 output tokens at $24 per million = $16.80
    # Total: $19.20
    assert_in_delta 19.20, cost, 0.01

    # Test with Claude 3.5 Haiku pricing
    # Initialize with a fully qualified model name to avoid resolution
    haiku_client = LLM::Anthropic::Client.new("claude-3-5-haiku-20241022")
    haiku_cost = haiku_client.calculate_cost_estimate(1_000_000)

    # Expected cost with Haiku pricing
    # - 300,000 input tokens at $1.25 per million = $0.375
    # - 700,000 output tokens at $3.75 per million = $2.625
    # Total: $3.00
    assert_in_delta 3.00, haiku_cost, 0.01
  end

  test "validate_api_key returns true for valid key" do
    # Setup mock HTTP response for models endpoint
    @mock_response.stubs(:code).returns("200")
    @mock_http.expects(:request).returns(@mock_response)

    assert @client.validate_api_key
  end

  test "validate_api_key returns false for invalid key" do
    # Setup mock HTTP error response for models endpoint
    @mock_response.stubs(:code).returns("401")
    @mock_http.expects(:request).returns(@mock_response)

    refute @client.validate_api_key
  end

  test "validate_api_key handles exceptions gracefully" do
    # Setup mock to raise exception
    @mock_http.expects(:request).raises(StandardError)

    refute @client.validate_api_key
  end

  test "resolves generic model names to fully specified versions in API requests" do
    # Setup
    generic_model = "claude-3-5-sonnet"
    client = LLM::Anthropic::Client.new(generic_model)

    # Expected fully specified model (latest version from PRICING constant)
    expected_model = "claude-3-5-sonnet-20241022"

    # Setup mock for HTTP request capture
    request_body = nil
    @mock_http.expects(:request).with do |request|
      request_body = JSON.parse(request.body)
      true
    end.returns(
      stub(
        code: "200",
        body: {
          id: "msg_123",
          content: [ { type: "text", text: "This is a test response" } ],
          usage: { input_tokens: 10, output_tokens: 15 }
        }.to_json
      )
    )

    # Exercise
    client.execute_request(prompt: "Test prompt")

    # Verify
    assert_equal expected_model, request_body["model"],
      "Generic model name should be resolved to the latest fully specified version"
  end

  test "does not modify already fully specified model names" do
    # Setup
    fully_specified_model = "claude-3-5-sonnet-20240620" # An older version
    client = LLM::Anthropic::Client.new(fully_specified_model)

    # Setup mock for HTTP request capture
    request_body = nil
    @mock_http.expects(:request).with do |request|
      request_body = JSON.parse(request.body)
      true
    end.returns(
      stub(
        code: "200",
        body: {
          id: "msg_123",
          content: [ { type: "text", text: "This is a test response" } ],
          usage: { input_tokens: 10, output_tokens: 15 }
        }.to_json
      )
    )

    # Exercise
    client.execute_request(prompt: "Test prompt")

    # Verify
    assert_equal fully_specified_model, request_body["model"],
      "Fully specified model names should not be modified"
  end
end
