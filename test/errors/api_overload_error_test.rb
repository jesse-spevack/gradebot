# frozen_string_literal: true

require "test_helper"

class ApiOverloadErrorTest < ActiveSupport::TestCase
  setup do
    @original_error = StandardError.new("Original error")
    @error = ApiOverloadError.new(
      "Anthropic API error (529): Overloaded",
      retry_after: 5,
      original_error: @original_error
    )
  end

  test "initializes with message" do
    assert_equal "Anthropic API error (529): Overloaded", @error.message
  end

  test "stores retry_after value" do
    assert_equal 5, @error.retry_after
  end

  test "stores original error" do
    assert_equal @original_error, @error.original_error
  end

  test "is retryable" do
    assert @error.retryable?
  end

  test "works without optional parameters" do
    error = ApiOverloadError.new("Simple message")
    assert_equal "Simple message", error.message
    assert_nil error.retry_after
    assert_nil error.original_error
    assert @error.retryable?
  end
end
