# frozen_string_literal: true

module LLM
  # Tracks and records LLM usage costs
  class CostTracker
    # Generates a tracking context hash for an LLM request
    # @param request_type [String, nil] The type of request being made
    # @param trackable [Object, nil] The object being processed (e.g., a submission)
    # @param user [User, nil] The user making the request
    # @param metadata [Hash] Additional metadata to include
    # @return [Hash] A context hash for tracking
    def self.generate_context(request_type: nil, trackable: nil, user: nil, metadata: {})
      {
        request_id: SecureRandom.uuid,
        request_type: request_type,
        trackable: trackable,
        user: user,
        metadata: metadata || {}
      }
    end

    # Records cost data to the database
    # @param cost_data [Hash] The cost data to record
    # @param context [Hash] The context information for the request
    # @return [LLMCostLog] The created log entry
    def self.record(cost_data, context = {})
      # Add detailed debugging information
      Rails.logger.debug "LLM Cost Tracking - Recording cost data:"
      Rails.logger.debug "  - Model: #{cost_data[:llm_model_name]}"
      Rails.logger.debug "  - Request Type: #{context[:request_type]}"
      Rails.logger.debug "  - Request ID: #{context[:request_id] || cost_data[:request_id]}"
      Rails.logger.debug "  - Tokens: #{cost_data[:total_tokens]} (prompt: #{cost_data[:prompt_tokens]}, completion: #{cost_data[:completion_tokens]})"
      Rails.logger.debug "  - Cost: #{cost_data[:cost]}"
      Rails.logger.debug "  - User: #{context[:user]&.id}"
      Rails.logger.debug "  - Trackable: #{context[:trackable]&.class&.name}:#{context[:trackable]&.id}"

      begin
        # Validate that llm_model_name is present
        if cost_data[:llm_model_name].nil?
          Rails.logger.error "LLM Cost Tracking - No llm_model_name provided in cost data"
          raise ArgumentError, "llm_model_name is required"
        end

        LLMCostLog.create!(
          user: context[:user],
          trackable: context[:trackable],
          request_type: context[:request_type],
          request_id: context[:request_id] || cost_data[:request_id],
          llm_model_name: cost_data[:llm_model_name],
          prompt_tokens: cost_data[:prompt_tokens] || 0,
          completion_tokens: cost_data[:completion_tokens] || 0,
          total_tokens: cost_data[:total_tokens] || 0,
          cost: cost_data[:cost] || 0,
          metadata: context[:metadata]
        )

        Rails.logger.info "LLM Cost Tracking - Successfully recorded cost log"
      rescue => e
        Rails.logger.error "LLM Cost Tracking - Failed to create cost log: #{e.message}"
        Rails.logger.error "LLM Cost Tracking - Error backtrace: #{e.backtrace&.first(5)&.join("\n")}"
        Rails.logger.error "LLM Cost Tracking - Cost data: #{cost_data.inspect}"
        Rails.logger.error "LLM Cost Tracking - Context: #{context.inspect}"

        # Re-raise the error in test environment for easier debugging
        raise if Rails.env.test?
      end
    end
  end
end
