# frozen_string_literal: true

module LLM
  # Handles retrying operations with different strategies based on error type
  class RetryHandler
    def initialize
      @retry_count = 0
      @current_model_name = nil
    end

    # Execute a block with retries
    #
    # @param model_name [String, nil] The name of the model being used
    # @yield The block to execute with retries
    # @return [Object] The result of the block
    def with_retries(model_name = nil)
      @retry_count = 0
      @current_model_name = model_name

      begin
        yield
      rescue LLM::Errors::AnthropicOverloadError => e
        # Log the overload error
        Rails.logger.warn("Anthropic API overloaded (529): #{e.message}, retry after: #{e.retry_after}s")

        # Record the failure in the circuit breaker
        circuit_breaker = CircuitBreaker.new("anthropic:#{current_model_name}")
        circuit_breaker.record_failure

        # Handle retry with specific strategy for overload errors
        handle_retry(e) { yield }
      rescue ::ApiOverloadError => e
        # Log the rate limit error
        Rails.logger.warn("Anthropic API rate limited (429): #{e.message}, retry after: #{e.retry_after}s")

        # Handle retry with specific strategy for rate limit errors
        handle_retry(e) { yield }
      rescue StandardError => e
        # Log other errors
        Rails.logger.error("Error in LLM request: #{e.message}")

        # Re-raise the error
        raise e
      end
    end

    private

    # Get the current model name or "unknown" if not set
    #
    # @return [String] The current model name
    def current_model_name
      @current_model_name || "unknown"
    end

    # Handle retry based on error type
    #
    # @param error [StandardError] The error that occurred
    # @yield The block to retry
    # @return [Object] The result of the block
    def handle_retry(error)
      case error
      when LLM::Errors::AnthropicOverloadError
        # Overload-specific retry strategy
        retry_with_backoff(max_retries: 2, base_delay: error.retry_after || 60) { yield }
      when ::ApiOverloadError
        # Rate limit-specific retry strategy
        retry_with_backoff(max_retries: 3, base_delay: error.retry_after || 30) { yield }
      else
        # Default retry strategy
        retry_with_backoff(max_retries: 2, base_delay: 5) { yield }
      end
    end

    # Retry with exponential backoff
    #
    # @param max_retries [Integer] Maximum number of retries
    # @param base_delay [Integer] Base delay in seconds
    # @yield The block to retry
    # @return [Object] The result of the block
    def retry_with_backoff(max_retries:, base_delay:)
      # Increment retry counter before checking max_retries
      @retry_count += 1

      if @retry_count > max_retries
        Rails.logger.error("Max retries (#{max_retries}) exceeded for #{current_model_name}")
        raise  # Re-raise the original error
      end

      # Calculate backoff with jitter
      delay = calculate_backoff(base_delay, @retry_count - 1)
      Rails.logger.info("Retrying request to #{current_model_name} in #{delay}s (attempt #{@retry_count}/#{max_retries})")

      # Sleep for the calculated delay
      sleep(delay)

      # Retry the original block
      yield
    end

    # Calculate backoff with jitter
    #
    # @param base_delay [Integer] Base delay in seconds
    # @param retry_count [Integer] Current retry count
    # @return [Float] Calculated delay with jitter
    def calculate_backoff(base_delay, retry_count)
      # Exponential backoff with jitter
      # Formula: base_delay * (2 ^ retry_count) * (0.85 + rand * 0.3)
      jitter = 0.85 + rand * 0.3
      base_delay * (2 ** retry_count) * jitter
    end
  end
end
