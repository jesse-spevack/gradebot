# frozen_string_literal: true

require "test_helper"

class ServiceUnavailableErrorTest < ActiveSupport::TestCase
  test "initializes with default values" do
    error = LLM::ServiceUnavailableError.new

    assert_equal "Service temporarily unavailable", error.message
    assert_equal 150, error.retry_after
  end

  test "accepts custom values" do
    error = LLM::ServiceUnavailableError.new(
      "Custom unavailable message",
      retry_after: 300
    )

    assert_equal "Custom unavailable message", error.message
    assert_equal 300, error.retry_after
  end

  test "is retryable" do
    error = LLM::ServiceUnavailableError.new
    assert error.retryable?
  end
end
