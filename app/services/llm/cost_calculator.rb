# frozen_string_literal: true

module LLM
  # Calculates the cost of LLM usage based on token counts
  class CostCalculator
    # Calculate the cost for a completed request with known token counts
    # @param llm_model_name [String] the name of the LLM model used
    # @param prompt_tokens [Integer] number of tokens in the prompt
    # @param completion_tokens [Integer] number of tokens in the completion
    # @return [Hash] containing prompt_cost, completion_cost, and total_cost
    def self.calculate(llm_model_name, prompt_tokens, completion_tokens)
      pricing = LLMPricingConfig.for_model(llm_model_name)
      return zero_cost if pricing.nil?

      prompt_cost = (prompt_tokens * pricing.prompt_rate) / 1_000_000
      completion_cost = (completion_tokens * pricing.completion_rate) / 1_000_000

      {
        prompt_cost: prompt_cost,
        completion_cost: completion_cost,
        total_cost: prompt_cost + completion_cost
      }
    end

    # Get the pricing rates for a specific model
    # @param llm_model_name [String] the name of the LLM model
    # @return [Hash] containing prompt and completion rates
    def self.get_rates_for_model(llm_model_name)
      pricing = LLMPricingConfig.for_model(llm_model_name)
      {
        prompt: pricing.prompt_rate,
        completion: pricing.completion_rate
      }
    end

    # Get all pricing rates from the database
    # @return [Hash] a hash of model names to rate hashes
    def self.pricing_rates
      rates = {}
      LLMPricingConfig.all.each do |config|
        rates[config.llm_model_name] = {
          prompt: config.prompt_rate,
          completion: config.completion_rate
        }
      end
      rates
    end

    # Get the default pricing rate
    # @return [Hash] containing prompt and completion rates
    def self.default_rate
      pricing = LLMPricingConfig.find_by(llm_model_name: "default")

      if pricing
        {
          prompt: pricing.prompt_rate,
          completion: pricing.completion_rate
        }
      else
        # Hardcoded fallback if no default in database
        {
          prompt: 10.0,
          completion: 30.0
        }
      end
    end

    private

    def self.zero_cost
      {
        prompt_cost: 0.0,
        completion_cost: 0.0,
        total_cost: 0.0
      }
    end
  end
end
