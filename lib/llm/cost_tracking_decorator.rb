module LLM
  class CostTrackingDecorator
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def execute_request(input_object)
      # Extract context from options
      context = input_object[:context] || {}
      context[:request_id] ||= SecureRandom.uuid

      # Execute the original request
      response = client.execute_request(input_object)

      # Extract token usage from response
      if response.is_a?(Hash) && response[:metadata]
        tokens = response[:metadata][:tokens] || {}

        # Calculate cost
        cost_data = {
          llm_model_name: llm_model_name,
          prompt_tokens: tokens[:prompt] || 0,
          completion_tokens: tokens[:completion] || 0,
          total_tokens: tokens[:total] || 0,
          cost: response[:metadata][:cost] ||
                CostTracking.calculate_cost(
                  llm_model_name,
                  tokens[:prompt] || 0,
                  tokens[:completion] || 0
                ),
          request_id: context[:request_id]
        }

        # Record cost data
        CostTracking.record(cost_data, context)
      end

      # Return original response
      response
    end

    # Get the model name from the client
    def llm_model_name
      client.model_name
    end

    # Delegate all other methods to the wrapped client
    def method_missing(method_name, *args, &block)
      @client.send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      @client.respond_to?(method_name, include_private) || super
    end
  end
end
