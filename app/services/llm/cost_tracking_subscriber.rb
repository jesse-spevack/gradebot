module LLM
  # Subscribes to LLM events and handles cost tracking
  class CostTrackingSubscriber
    include EventSystem::Subscriber

    def initialize
      # Subscribe to the request completed event
      subscribe_to(EventSystem::EVENTS[:request_completed])
    end

    # Handle the llm.request.completed event - method name matches the event with dots replaced by underscores
    def on_llm_request_completed(payload)
      Rails.logger.debug "CostTrackingSubscriber - Processing completed request"

      # Extract necessary data from payload
      llm_request = payload[:request]
      response = payload[:response]
      context = payload[:context] || {}

      # Skip if we don't have token information
      return unless response.is_a?(Hash) && response[:metadata] && response[:metadata][:tokens]

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

      Rails.logger.debug "CostTrackingSubscriber - Recording cost: #{cost_data[:cost]}"

      # Record cost data
      CostTracking.record(cost_data, context)
    end
  end
end
