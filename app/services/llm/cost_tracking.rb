module LLM
  module CostTracking
    # Generates a tracking context hash for an LLM request
    def self.generate_context(request_type: nil, trackable: nil, user: nil, metadata: {})
      CostTracker.generate_context(
        request_type: request_type,
        trackable: trackable,
        user: user,
        metadata: metadata
      )
    end

    # Records cost data to the database
    def self.record(cost_data, context = {})
      CostTracker.record(cost_data, context)
    end

    # Calculate token cost based on model & usage
    def self.calculate_cost(llm_model_name, prompt_tokens, completion_tokens)
      cost_data = CostCalculator.calculate(llm_model_name, prompt_tokens, completion_tokens)
      # Handle both hash and float return values
      cost_data.is_a?(Hash) ? cost_data[:total_cost] : cost_data
    end

    # Current pricing rates per 1M tokens (MTok)
    def self.pricing_rates
      CostCalculator.pricing_rates
    end

    def self.default_rate
      CostCalculator.default_rate
    end
  end
end
