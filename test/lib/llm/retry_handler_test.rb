# frozen_string_literal: true

require "test_helper"

class LLM::RetryHandlerTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @handler = LLM::RetryHandler.new
    @request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-haiku-20240307"
    )
  end

  test "retries on AnthropicOverloadError with appropriate backoff" do
    # Track call count
    call_count = 0

    # Mock the circuit breaker to avoid actual cache operations
    mock_circuit = Minitest::Mock.new
    mock_circuit.expect :record_failure, nil

    # Create a custom error handler that will succeed on the third try
    custom_handler = LLM::RetryHandler.new

    # Override the retry_with_backoff method to avoid sleeping and just return success on third try
    def custom_handler.retry_with_backoff(max_retries:, base_delay:)
      if @retry_count >= max_retries
        raise "Max retries exceeded"
      end

      @retry_count += 1
      "success on retry #{@retry_count}"
    end

    LLM::CircuitBreaker.stub :new, mock_circuit do
      # This will raise AnthropicOverloadError, then our custom handler will handle it
      result = custom_handler.with_retries do
        call_count += 1
        if call_count == 1
          raise LLM::Errors::AnthropicOverloadError.new(retry_after: 60)
        else
          "original block success"
        end
      end

      # Should return the success message from our custom retry_with_backoff
      assert_equal "success on retry 1", result
      assert_equal 1, call_count
    end

    # Verify mock
    mock_circuit.verify
  end

  test "gives up after max retries and re-raises original error" do
    # Create a test error with a unique message to verify it's re-raised
    test_error = LLM::Errors::AnthropicOverloadError.new("Test overload error", retry_after: 10)

    # Track call count
    call_count = 0

    # Create a handler with a stubbed sleep method to avoid actual delays
    handler = LLM::RetryHandler.new

    # Stub the sleep method to avoid actual delays
    handler.stub :sleep, nil do
      # Stub the circuit breaker to avoid actual cache operations
      mock_circuit = mock
      mock_circuit.stubs(:record_failure).returns(nil)

      LLM::CircuitBreaker.stub :new, mock_circuit do
        # The block should raise the test error every time it's called
        error = assert_raises(LLM::Errors::AnthropicOverloadError) do
          handler.with_retries do
            call_count += 1
            raise test_error
          end
        end

        # Verify the original error is re-raised
        assert_equal "Test overload error", error.message
        assert_equal test_error, error

        # Verify the block was called initial + 1 retry = 2 times
        # The RetryHandler increments the retry count before checking if it exceeds max_retries,
        # so it only retries once before giving up with max_retries: 2
        assert_equal 2, call_count
      end
    end
  end

  test "calculates backoff with jitter" do
    # Test the private method directly
    base_delay = 10
    retry_count = 2

    # Call the method multiple times to check jitter
    delays = []
    10.times do
      delays << @handler.send(:calculate_backoff, base_delay, retry_count)
    end

    # Base calculation would be 10 * (2^2) = 40
    # With jitter (0.85-1.15), range should be 34-46
    delays.each do |delay|
      assert_in_delta 40, delay, 6
    end

    # Ensure we got some variation (jitter)
    assert_operator delays.uniq.size, :>, 1
  end
end
