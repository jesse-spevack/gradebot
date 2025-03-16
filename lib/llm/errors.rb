# frozen_string_literal: true

module LLM
  module Errors
    # Custom error raised when an unsupported model is requested
    class UnsupportedModelError < StandardError
      def initialize(model_name)
        super("Unsupported model: #{model_name}. No client available for this model type.")
      end
    end

    # Custom error class for Anthropic API overload errors (HTTP 529)
    class AnthropicOverloadError < StandardError
      attr_reader :retry_after, :status_code

      def initialize(message = "Anthropic API is overloaded", retry_after: 60, status_code: 529)
        @retry_after = retry_after
        @status_code = status_code
        super(message)
      end

      def retryable?
        true
      end
    end

    # Custom error class for service unavailable errors (circuit breaker open)
    class ServiceUnavailableError < StandardError
      attr_reader :retry_after

      def initialize(message = "Service temporarily unavailable", retry_after: 150)
        @retry_after = retry_after
        super(message)
      end

      def retryable?
        true
      end
    end
  end

  # Alias the error classes at the module level for convenience
  AnthropicOverloadError = Errors::AnthropicOverloadError
  ServiceUnavailableError = Errors::ServiceUnavailableError
end
