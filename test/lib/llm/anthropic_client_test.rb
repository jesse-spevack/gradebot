# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class LLM::AnthropicClientTest < ActiveSupport::TestCase
  setup do
    # Mock the API key
    @client = LLM::Anthropic::Client.new(api_key: "test_api_key")
    @request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-haiku-20240307"
    )
  end

  test "raises AnthropicOverloadError on 529 response" do
    # Use WebMock to simulate a 529 response
    stub_request(:post, /api\.anthropic\.com/)
      .to_return(
        status: 529,
        headers: { "retry-after" => "60" },
        body: { error: { type: "overloaded" } }.to_json
      )

    error = assert_raises(LLM::Errors::AnthropicOverloadError) do
      @client.execute_request(@request)
    end

    assert_equal 60, error.retry_after
    assert_equal 529, error.status_code
  end

  test "raises ApiOverloadError on 429 response" do
    # Use WebMock to simulate a 429 response
    stub_request(:post, /api\.anthropic\.com/)
      .to_return(
        status: 429,
        headers: { "retry-after" => "30" },
        body: { error: { type: "rate_limit_exceeded" } }.to_json
      )

    error = assert_raises(ApiOverloadError) do
      @client.execute_request(@request)
    end

    assert_equal 30, error.retry_after
  end

  test "handles missing retry-after header" do
    # Use WebMock to simulate a 529 response without retry-after header
    stub_request(:post, /api\.anthropic\.com/)
      .to_return(
        status: 529,
        body: { error: { type: "overloaded" } }.to_json
      )

    error = assert_raises(LLM::Errors::AnthropicOverloadError) do
      @client.execute_request(@request)
    end

    # Should use default retry_after value
    assert_equal 60, error.retry_after
  end
end
