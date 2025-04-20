# frozen_string_literal: true

module LLM
  # Handles communication with LLM services
  class Client
    # Initialize the LLM client service
    #
    # @param config [Hash] Configuration for the client (for backwards compatibility)
    def initialize(config = {})
      # Nothing to initialize
    end

    # Generate a response using the LLM
    #
    # @param llm_request [LLMRequest] The request object containing prompt and parameters
    # @return [Hash] The response with content and metadata
    def generate(llm_request)
      Rails.logger.info("Calling LLM with model: #{llm_request.llm_model_name}")
      # Validate the request
      unless llm_request.is_a?(LLMRequest)
        raise ArgumentError, "Expected LLMRequest object, got #{llm_request.class.name}"
      end

      unless llm_request.valid?
        raise ArgumentError, "Invalid LLMRequest: #{llm_request.errors.full_messages.join(', ')}"
      end

      # Check circuit breaker
      model_name = llm_request.llm_model_name
      circuit_breaker = LLM::CircuitBreaker.new("anthropic:#{model_name}")

      # Check if circuit allows request
      unless circuit_breaker.allow_request?
        Rails.logger.warn("Circuit breaker open for #{model_name}, rejecting request")
        raise LLM::ServiceUnavailableError.new(
          "Anthropic API temporarily unavailable due to repeated failures. Please try again later."
        )
      end

      # Get the LLM client
      llm_client = LLM::ClientFactory.create

      # Log client type for debugging
      Rails.logger.debug("LLM client type: #{llm_client.class.name}")
      Rails.logger.debug("LLM client object: #{llm_client.inspect}")

      # Log the context details for debugging
      context = llm_request.to_context
      Rails.logger.debug("Request context: #{context.inspect}")

      # Create a retry handler for this request
      retry_handler = LLM::RetryHandler.new

      # Generate the response with retries
      retry_handler.with_retries(model_name) do
        response = llm_client.generate(llm_request)

        # Record success in circuit breaker
        circuit_breaker.record_success

        # Log the raw response for debugging
        Rails.logger.debug("RAW LLM RESPONSE BEGIN")
        Rails.logger.debug(response[:content].to_s)
        Rails.logger.debug("RAW LLM RESPONSE END")

        # Log metadata for debugging
        if response[:metadata]
          Rails.logger.debug("Response metadata: #{response[:metadata].inspect}")

          # Check for token information
          if response[:metadata][:tokens]
            tokens = response[:metadata][:tokens]
            Rails.logger.debug("Token info present - prompt: #{tokens[:prompt]}, completion: #{tokens[:completion]}, total: #{tokens[:total]}")
          else
            Rails.logger.warn("Response metadata doesn't contain token information")
          end

          # Check for cost information
          if response[:metadata][:cost]
            Rails.logger.debug("Cost information present: #{response[:metadata][:cost]}")
          else
            Rails.logger.warn("Response metadata doesn't contain cost information")
          end
        else
          Rails.logger.warn("Response does not contain metadata")
        end

        response
      end
    end
  end
end
