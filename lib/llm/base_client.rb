# frozen_string_literal: true

require_relative "logging"
require_relative "../../app/services/llm/cost_tracking"
require_relative "../../app/services/llm/event_system"

module LLM
  # Abstract base class for LLM clients
  #
  # This class provides a common interface and shared functionality for
  # all LLM provider-specific clients. It handles:
  # - Request logging and tracking
  # - Execution time measurement
  # - Cost tracking and calculation
  # - Error handling
  #
  # Provider-specific implementations should override the abstract methods:
  # - execute_request
  # - calculate_token_count
  #
  # @abstract Subclass and override abstract methods to implement
  # @example
  #   class AnthropicClient < LLM::BaseClient
  #     def execute_request(llm_request)
  #       # Implementation for Anthropic
  #     end
  #
  #     def calculate_token_count(llm_request)
  #       # Implementation for Anthropic token counting
  #     end
  #   end
  #
  class BaseClient
    # Generate a response using the LLM
    #
    # Handles logging, timing, error handling, and enriches the response
    # with metadata about tokens, costs, and execution time.
    #
    # @param llm_request [LLMRequest] The request object containing prompt and parameters
    # @return [Hash] The response with content and metadata
    def generate(llm_request)
      # Validate that we received a proper LLMRequest
      unless llm_request.is_a?(LLMRequest)
        raise ArgumentError, "Expected LLMRequest object, got #{llm_request.class.name}"
      end

      # Validate the request object
      unless llm_request.valid?
        raise ArgumentError, "Invalid LLMRequest: #{llm_request.errors.full_messages.join(', ')}"
      end

      # Get the context for cost tracking and logging
      context = llm_request.to_context

      # Calculate token count for tracking before the operation
      prompt_token_count = calculate_token_count(llm_request)

      # Use the operation tracking to handle timing and logging
      log_context = {
        model: llm_request.llm_model_name,
        request_type: llm_request.request_type,
        prompt_tokens: prompt_token_count
      }

      Logging.operation("LLM Request", log_context) do
        begin
          # Log cost tracking information
          Rails.logger.debug "LLM Cost Tracking - Executing request"
          Rails.logger.debug "  - Model: #{llm_request.llm_model_name}"
          Rails.logger.debug "  - Request ID: #{context[:request_id]}"
          Rails.logger.debug "  - Request Type: #{context[:request_type]}"

          # Execute the actual request to the LLM provider
          response = execute_request(llm_request)

          # Log completion
          Rails.logger.debug "LLM Request - Received response from provider"

          # Try to publish the event for cost tracking
          begin
            Rails.logger.info "LLM Request - Publishing event for cost tracking"
            EventSystem::Publisher.publish(
              EventSystem::EVENTS[:request_completed],
              {
                request: llm_request,
                response: response,
                context: context
              }
            )
            Rails.logger.info "LLM Request - Event published successfully"
          rescue => e
            Rails.logger.error "LLM Request - Failed to publish event: #{e.message}"
            Rails.logger.error "LLM Request - Error backtrace: #{e.backtrace&.first(5)&.join("\n")}"

            # Fallback: Direct cost tracking if event system fails
            Rails.logger.info "LLM Request - Attempting direct cost tracking as fallback"
            track_cost_directly(llm_request, response, context)
          end

          # Return the response
          response
        rescue => e
          Rails.logger.error "Error in LLM request: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          raise
        end
      end
    end

    # Fallback method to track costs directly if the event system fails
    # @param llm_request [LLMRequest] The request object
    # @param response [Hash] The response from the LLM
    # @param context [Hash] The context for tracking
    def track_cost_directly(llm_request, response, context)
      begin
        # Skip if we don't have token information
        unless response.is_a?(Hash) && response[:metadata] && response[:metadata][:tokens]
          Rails.logger.warn "LLM Request - Missing token information in response, skipping fallback cost tracking"
          return
        end

        tokens = response[:metadata][:tokens]

        # Calculate cost
        cost = CostTracking.calculate_cost(
          llm_request.llm_model_name,
          tokens[:prompt] || 0,
          tokens[:completion] || 0
        )

        # Create cost data for tracking
        cost_data = {
          llm_model_name: llm_request.llm_model_name,
          prompt_tokens: tokens[:prompt] || 0,
          completion_tokens: tokens[:completion] || 0,
          total_tokens: tokens[:total] || 0,
          cost: cost,
          request_id: context[:request_id]
        }

        Rails.logger.info "LLM Request - Fallback cost tracking: #{cost_data[:cost]}"

        # Record cost data directly
        CostTracking.record(cost_data, context)
        Rails.logger.info "LLM Request - Fallback cost tracking completed successfully"
      rescue => e
        Rails.logger.error "LLM Request - Fallback cost tracking failed: #{e.message}"
        Rails.logger.error "LLM Request - Error backtrace: #{e.backtrace&.first(5)&.join("\n")}"
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
    # @param llm_request [LLMRequest] The request object for the LLM
    # @return [Hash] The response from the LLM
    # @raise [NotImplementedError] If not implemented in a subclass
    def execute_request(llm_request)
      raise NotImplementedError, "#{self.class.name} must implement #execute_request"
    end

    # Calculate the token count for an input
    #
    # @abstract Override this method in provider-specific implementations
    # @param llm_request [LLMRequest] The request object to calculate tokens for
    # @return [Integer] The token count
    # @raise [NotImplementedError] If not implemented in a subclass
    def calculate_token_count(llm_request)
      raise NotImplementedError, "#{self.class.name} must implement #calculate_token_count"
    end
  end
end
