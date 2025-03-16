# frozen_string_literal: true

require "test_helper"

class AnthropicOverloadErrorTest < ActiveSupport::TestCase
  test "initializes with default values" do
    error = LLM::AnthropicOverloadError.new

    assert_equal "Anthropic API is overloaded", error.message
    assert_equal 60, error.retry_after
    assert_equal 529, error.status_code
  end

  test "accepts custom values" do
    error = LLM::AnthropicOverloadError.new(
      "Custom message",
      retry_after: 120,
      status_code: 530
    )

    assert_equal "Custom message", error.message
    assert_equal 120, error.retry_after
    assert_equal 530, error.status_code
  end

  test "is retryable" do
    error = LLM::AnthropicOverloadError.new
    assert error.retryable?
  end
end
