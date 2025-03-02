# frozen_string_literal: true

require_relative "logging"

module LLM
  # Abstract base class for LLM clients
  #
  # This class provides a common interface and shared functionality for
  # all LLM provider-specific clients. It handles:
  # - Request logging and tracking
  # - Execution time measurement
  # - Cost and token counting
  # - Error handling
  #
  # Provider-specific implementations should override the abstract methods:
  # - execute_request
  # - calculate_token_count
  # - calculate_cost_estimate
  #
  # @abstract Subclass and override abstract methods to implement
  # @example
  #   class OpenAIClient < LLM::BaseClient
  #     def execute_request(input_object)
  #       # Implementation for OpenAI
  #     end
  #
  #     def calculate_token_count(input_object)
  #       # Implementation for OpenAI token counting
  #     end
  #
  #     def calculate_cost_estimate(token_count)
  #       # Implementation for OpenAI cost calculation
  #     end
  #   end
  #
  class BaseClient
    attr_reader :model_name

    # Initialize a new LLM client
    #
    # @param model_name [String] The name of the model to use
    def initialize(model_name)
      @model_name = model_name
    end

    # Generate a response using the LLM
    #
    # Handles logging, timing, error handling, and enriches the response
    # with metadata about tokens, cost, and execution time.
    #
    # @param input_object [Hash] The input containing the prompt and any parameters
    # @return [Hash] The response with content and metadata
    def generate(input_object)
      # Calculate token count for tracking before the operation
      prompt_token_count = calculate_token_count(input_object)

      # Use the operation tracking to handle timing and logging
      log_context = {
        model: model_name,
        input_type: input_object.class.name,
        prompt_tokens: prompt_token_count
      }

      Logging.operation("LLM Request", log_context) do
        begin
          # Execute the actual request to the LLM provider
          response = execute_request(input_object)

          # Get token counts from response
          token_counts = response[:metadata][:tokens]

          # Calculate cost based on token usage
          cost = calculate_cost_estimate(token_counts[:total])

          # Enrich response with additional metadata
          enriched_response = {
            content: response[:content],
            metadata: response[:metadata].merge({
              execution_time_ms: Thread.current[:llm_operation_duration],
              cost: cost,
              model: model_name
            })
          }

          # Log the successful completion with token and cost information
          Logging.info("LLM request completed successfully", {
            model: model_name,
            tokens: token_counts,
            cost: cost
          })

          enriched_response
        rescue => error
          # Log the error with detailed context
          Logging.error("Error in LLM request", {
            model: model_name,
            error: error,
            error_message: error.message,
            backtrace: error.backtrace&.first(5)
          })

          # Re-raise the error for the caller to handle
          raise
        end
      end
    end

    def llm_requests_are_disabled
      {
        content: "LLM requests are disabled",
        metadata: {
          tokens: 0,
          cost: 0
        }
      }
    end

    # Execute the actual request to the LLM provider
    #
    # @abstract Override this method in provider-specific implementations
    # @param input_object [Hash] The input for the LLM
    # @return [Hash] The response from the LLM
    # @raise [NotImplementedError] If not implemented in a subclass
    def execute_request(input_object)
      raise NotImplementedError, "#{self.class.name} must implement #execute_request"
    end

    # Calculate the token count for an input
    #
    # @abstract Override this method in provider-specific implementations
    # @param input_object [Hash] The input to calculate tokens for
    # @return [Integer] The token count
    # @raise [NotImplementedError] If not implemented in a subclass
    def calculate_token_count(input_object)
      raise NotImplementedError, "#{self.class.name} must implement #calculate_token_count"
    end

    # Calculate the cost estimate based on token count
    #
    # @abstract Override this method in provider-specific implementations
    # @param token_count [Integer] The token count to calculate cost for
    # @return [Float] The estimated cost
    # @raise [NotImplementedError] If not implemented in a subclass
    def calculate_cost_estimate(token_count)
      raise NotImplementedError, "#{self.class.name} must implement #calculate_cost_estimate"
    end
  end
end
