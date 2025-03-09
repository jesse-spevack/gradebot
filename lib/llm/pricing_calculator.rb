module LLM
  # Calculates LLM costs based on model and token usage
  class PricingCalculator
    # Calculate cost based on model and token usage
    # @param llm_model_name [String] The name of the LLM model
    # @param prompt_tokens [Integer] Number of tokens in the prompt
    # @param completion_tokens [Integer] Number of tokens in the completion
    # @return [Float] The calculated cost in dollars
    def self.calculate_cost(llm_model_name, prompt_tokens, completion_tokens)
      rates = pricing_rates[llm_model_name] || default_rate

      prompt_cost = prompt_tokens * rates[:prompt] / 1000.0
      completion_cost = completion_tokens * rates[:completion] / 1000.0

      (prompt_cost + completion_cost).round(6)
    end

    # Current pricing rates per 1K tokens (as of March 2024)
    # Should be updated as pricing changes
    # @return [Hash] Mapping of model names to rate hashes
    def self.pricing_rates
      {
        "claude-3-opus" => { prompt: 15.0, completion: 75.0 },
        "claude-3-sonnet" => { prompt: 3.0, completion: 15.0 },
        "claude-3-haiku" => { prompt: 0.25, completion: 1.25 },
        "gpt-4o" => { prompt: 5.0, completion: 15.0 },
        "gpt-4-turbo" => { prompt: 10.0, completion: 30.0 },
        "gpt-4" => { prompt: 30.0, completion: 60.0 },
        "gpt-3.5-turbo" => { prompt: 0.5, completion: 1.5 },
        "gemini-pro" => { prompt: 0.125, completion: 0.375 }
        # Add other models as needed
      }
    end

    # Default rate to use when the model is not found in pricing_rates
    # @return [Hash] Default rate for prompt and completion tokens
    def self.default_rate
      { prompt: 10.0, completion: 30.0 }
    end
  end
end
