# frozen_string_literal: true

require "test_helper"

class LLM::Anthropic::ClientTest < ActiveSupport::TestCase
  include LLMTestHelper

  setup do
    # Stub the API key instead of manipulating ENV
    stub_anthropic_api_key

    # Create client instance
    @client = LLM::Anthropic::Client.new

    # Create a test LLMRequest
    @llm_request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-sonnet",
      max_tokens: 500,
      temperature: 0.5,
      request_type: "test"
    )

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

  test "initializes with default API key" do
    client = LLM::Anthropic::Client.new

    assert client.api_key.present?
    assert_match(/test-anthropic-key/, client.api_key)
  end

  test "accepts custom API key in options" do
    custom_key = "custom-api-key"
    client = LLM::Anthropic::Client.new(api_key: custom_key)

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
    response = @client.execute_request(@llm_request)

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
      @client.execute_request(@llm_request)
    end

    assert_match(/Anthropic API error/, error.message)
  end

  test "execute_request raises ApiOverloadError for rate limit errors" do
    # Setup mock HTTP rate limit response
    @mock_response.stubs(:code).returns("429")
    @mock_response.stubs(:[]).with("retry-after").returns("30")
    @mock_response.stubs(:body).returns({
      error: { message: "Rate limit exceeded" }
    }.to_json)
    @mock_http.expects(:request).returns(@mock_response)

    # Execute request and expect ApiOverloadError
    error = assert_raises(LLM::Errors::ApiOverloadError) do
      @client.execute_request(@llm_request)
    end

    # Verify error properties
    assert_match(/Anthropic API error \(429\)/, error.message)
    assert_equal 30, error.retry_after
    assert_not_nil error.original_error
    assert error.retryable?
  end

  test "execute_request uses default retry_after when not provided by API" do
    # Setup mock HTTP rate limit response without retry-after header
    @mock_response.stubs(:code).returns("429")
    @mock_response.stubs(:[]).with("retry-after").returns(nil)
    @mock_response.stubs(:body).returns({
      error: { message: "Rate limit exceeded" }
    }.to_json)
    @mock_http.expects(:request).returns(@mock_response)

    # Execute request and expect ApiOverloadError
    error = assert_raises(LLM::Errors::ApiOverloadError) do
      @client.execute_request(@llm_request)
    end

    # Verify default retry_after is used
    assert_equal 60, error.retry_after
  end

  test "calculate_token_count provides a reasonable approximation" do
    # Test with a known prompt
    @llm_request.prompt = "This is a test prompt with exactly 10 words."
    token_count = @client.calculate_token_count(@llm_request)

    # Verify token count is reasonable (10 words should be ~10-15 tokens)
    assert token_count > 5
    assert token_count < 20
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
    # Setup for HTTP request capture
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

    # Expected fully specified model
    expected_model = "claude-3-5-sonnet-20241022"

    # Exercise
    @client.execute_request(@llm_request)

    # Verify
    assert_equal expected_model, request_body["model"],
      "Generic model name should be resolved to the latest fully specified version"
  end

  test "does not modify already fully specified model names" do
    # Create request with a fully specified model name
    fully_specified_request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-sonnet-20240620", # An older version
      request_type: "test"
    )

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
    @client.execute_request(fully_specified_request)

    # Verify
    assert_equal "claude-3-5-sonnet-20240620", request_body["model"],
      "Fully specified model names should not be modified"
  end
end
