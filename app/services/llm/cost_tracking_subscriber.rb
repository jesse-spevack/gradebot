module LLM
  # Subscribes to LLM events and handles cost tracking
  class CostTrackingSubscriber
    include EventSystem::Subscriber

    def initialize
      Rails.logger.info "LLM::CostTrackingSubscriber - Initializing"

      begin
        # Subscribe to the request completed event
        event_name = EventSystem::EVENTS[:request_completed]
        Rails.logger.info "LLM::CostTrackingSubscriber - Subscribing to event: #{event_name}"
        subscribe_to(event_name)
        Rails.logger.info "LLM::CostTrackingSubscriber - Successfully subscribed to event"
      rescue => e
        Rails.logger.error "LLM::CostTrackingSubscriber - Failed to subscribe to event: #{e.message}"
        Rails.logger.error "LLM::CostTrackingSubscriber - Error backtrace: #{e.backtrace&.first(5)&.join("\n")}"
      end
    end

    # Handle the llm.request.completed event - method name matches the event with dots replaced by underscores
    def on_llm_request_completed(payload)
      Rails.logger.info "CostTrackingSubscriber - Processing completed request"

      begin
        # Extract necessary data from payload
        llm_request = payload[:request]
        response = payload[:response]
        context = payload[:context] || {}

        # Skip if we don't have token information
        unless response.is_a?(Hash) && response[:metadata] && response[:metadata][:tokens]
          Rails.logger.warn "CostTrackingSubscriber - Missing token information in response, skipping cost tracking"
          return
        end

        tokens = response[:metadata][:tokens]

        # Log token information
        Rails.logger.info "CostTrackingSubscriber - Token information: prompt=#{tokens[:prompt]}, completion=#{tokens[:completion]}, total=#{tokens[:total]}"

        # Calculate cost
        begin
          cost = CostTracking.calculate_cost(
            llm_request.llm_model_name,
            tokens[:prompt] || 0,
            tokens[:completion] || 0
          )
          Rails.logger.info "CostTrackingSubscriber - Calculated cost: #{cost}"
        rescue => e
          Rails.logger.error "CostTrackingSubscriber - Failed to calculate cost: #{e.message}"
          cost = 0
        end

        # Create cost data for tracking
        cost_data = {
          llm_model_name: llm_request.llm_model_name,
          prompt_tokens: tokens[:prompt] || 0,
          completion_tokens: tokens[:completion] || 0,
          total_tokens: tokens[:total] || 0,
          cost: cost,
          request_id: context[:request_id]
        }

        Rails.logger.info "CostTrackingSubscriber - Recording cost: #{cost_data[:cost]}"

        # Record cost data
        CostTracking.record(cost_data, context)

        Rails.logger.info "CostTrackingSubscriber - Successfully processed request"
      rescue => e
        Rails.logger.error "CostTrackingSubscriber - Error processing request: #{e.message}"
        Rails.logger.error "CostTrackingSubscriber - Error backtrace: #{e.backtrace&.first(5)&.join("\n")}"
      end
    end
  end
end
