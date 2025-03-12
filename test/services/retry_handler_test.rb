# frozen_string_literal: true

require "test_helper"

class RetryHandlerTest < ActiveSupport::TestCase
  test "executes block successfully without retries" do
    # No need to stub sleep since it won't be called
    result = RetryHandler.with_retry do
      "success"
    end
    assert_equal "success", result
  end

  test "retries once on specific error" do
    attempts = 0

    # Stub the sleep method at the Object level
    RetryHandler.any_instance.stubs(:sleep)

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

    # Stub the sleep method at the Object level
    RetryHandler.stubs(:sleep)

    assert_raises ApiOverloadError do
      RetryHandler.with_retry do
        attempts += 1
        raise ApiOverloadError.new("test error")
      end
    end

    assert_equal 4, attempts  # Default max_retries is now 3, so 4 attempts total (1 initial + 3 retries)
  end

  test "does not retry on other errors" do
    attempts = 0

    # No need to stub sleep since it won't be called
    assert_raises StandardError do
      RetryHandler.with_retry do
        attempts += 1
        raise StandardError
      end
    end

    assert_equal 1, attempts
  end

  test "uses retry_after value from ApiOverloadError" do
    attempts = 0
    expected_delay = 0.1  # Small value for testing

    # Create a mock error with retry_after
    error = ApiOverloadError.new("Rate limit exceeded", retry_after: expected_delay)

    # Verify the delay calculation without actually sleeping
    RetryHandler.expects(:sleep).with(expected_delay).once

    result = RetryHandler.with_retry(max_retries: 1) do
      attempts += 1
      raise error if attempts == 1
      "success"
    end

    assert_equal 2, attempts
    assert_equal "success", result
  end

  test "uses exponential backoff when retry_after not available" do
    attempts = 0
    base_delay = 0.1

    # Create a custom error class that doesn't have retry_after
    class CustomError < StandardError; end

    # Verify the delay calculation without actually sleeping
    RetryHandler.expects(:sleep).with(base_delay).once

    result = RetryHandler.with_retry(error_class: CustomError, max_retries: 1, base_delay: base_delay) do
      attempts += 1
      raise CustomError.new("test error") if attempts == 1
      "success"
    end

    assert_equal 2, attempts
    assert_equal "success", result
  end

  test "uses exponential backoff for multiple retries" do
    attempts = 0
    base_delay = 0.1

    # Set up a sequence of expectations for the sleep calls
    sequence = sequence("retry_sequence")
    RetryHandler.expects(:sleep).with(base_delay).in_sequence(sequence)
    RetryHandler.expects(:sleep).with(base_delay * 2).in_sequence(sequence)

    result = RetryHandler.with_retry(max_retries: 3, base_delay: base_delay) do
      attempts += 1
      raise ApiOverloadError.new("test error") if attempts <= 2
      "success"
    end

    assert_equal 3, attempts
    assert_equal "success", result
  end
end
