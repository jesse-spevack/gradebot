# frozen_string_literal: true

module LLM
  module Errors
    # Base error for LLM operations
    class BaseError < StandardError; end

    # Error for configuration issues (e.g., missing API key)
    class ConfigurationError < BaseError; end

    # Error for general API communication problems
    class ApiError < BaseError
      attr_reader :status_code, :response_body

      def initialize(message = "API Error", status_code: nil, response_body: nil)
        @status_code = status_code
        @response_body = response_body
        super(message)
      end
    end

    # Error specifically for API rate limits or overload situations
    class ApiOverloadError < ApiError
      attr_reader :retry_after

      def initialize(message = "API Overload/Rate Limit Exceeded", status_code: nil, response_body: nil, retry_after: nil)
        @retry_after = retry_after
        super(message, status_code: status_code, response_body: response_body)
      end

      def retryable?
        true # Typically overload errors are retryable
      end
    end

    # Custom error raised when an unsupported model is requested
    class UnsupportedModelError < BaseError
      def initialize(model_name)
        super("Unsupported model: #{model_name}. No client available for this model type.")
      end
    end

    # Custom error class for Anthropic API overload errors (HTTP 529)
    class AnthropicOverloadError < ApiOverloadError
      attr_reader :retry_after, :status_code

      def initialize(message = "Anthropic API is overloaded", retry_after: 60, status_code: 529)
        @retry_after = retry_after
        @status_code = status_code
        super(message, retry_after: retry_after, status_code: status_code)
      end
    end

    # Custom error class for service unavailable errors (circuit breaker open)
    class ServiceUnavailableError < ApiOverloadError
      attr_reader :retry_after

      def initialize(message = "Service temporarily unavailable", retry_after: 150)
        @retry_after = retry_after
        super(message, retry_after: retry_after)
      end
    end
  end

  # Alias the error classes at the module level for convenience
  AnthropicOverloadError = Errors::AnthropicOverloadError
  ServiceUnavailableError = Errors::ServiceUnavailableError
  BaseError = Errors::BaseError
  ConfigurationError = Errors::ConfigurationError
  ApiError = Errors::ApiError
  ApiOverloadError = Errors::ApiOverloadError
end
