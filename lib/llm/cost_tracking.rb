module LLM
  module CostTracking
    # Generates a tracking context hash for an LLM request
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
    def self.record(cost_data, context = {})
      LlmCostLog.create!(
        user: context[:user],
        trackable: context[:trackable],
        request_type: context[:request_type],
        request_id: context[:request_id] || cost_data[:request_id],
        llm_model_name: cost_data[:llm_model_name] || cost_data[:model_name],
        prompt_tokens: cost_data[:prompt_tokens],
        completion_tokens: cost_data[:completion_tokens],
        total_tokens: cost_data[:total_tokens],
        cost: cost_data[:cost],
        metadata: context[:metadata]
      )
    rescue => e
      Rails.logger.error "Failed to record LLM cost: #{e.message}"
      # Optionally, enqueue a retry job or alert
    end

    # Calculate cost based on model and token usage
    # Delegates to PricingCalculator for actual calculation
    def self.calculate_cost(model_name, prompt_tokens, completion_tokens)
      LLM::PricingCalculator.calculate_cost(model_name, prompt_tokens, completion_tokens)
    end
  end
end
