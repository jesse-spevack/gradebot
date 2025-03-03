# frozen_string_literal: true

require "test_helper"

class RetryHandlerTest < ActiveSupport::TestCase
  test "executes block successfully without retries" do
    result = RetryHandler.with_retry do
      "success"
    end
    assert_equal "success", result
  end

  test "retries once on specific error" do
    attempts = 0
    result = RetryHandler.with_retry do
      attempts += 1
      raise ApiOverloadError.new("test error") if attempts == 1
      "success"
    end
    assert_equal 2, attempts
    assert_equal "success", result
  end

  test "raises error after max retries" do
    attempts = 0
    assert_raises ApiOverloadError do
      RetryHandler.with_retry do
        attempts += 1
        raise ApiOverloadError.new("test error")
      end
    end
    assert_equal 2, attempts
  end

  test "does not retry on other errors" do
    attempts = 0
    assert_raises StandardError do
      RetryHandler.with_retry do
        attempts += 1
        raise StandardError
      end
    end
    assert_equal 1, attempts
  end
end
