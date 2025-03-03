# frozen_string_literal: true

# Helper class to manage strategy behavior and provide a consistent interface
class StrategyConfigurationHelper
  # Determines whether a strategy's parse method accepts context as a parameter
  # @param strategy [Object] The strategy object
  # @return [Boolean] true if the strategy accepts context, false otherwise
  def self.accepts_context?(strategy)
    # Check method arity
    # If arity < 0, it means variable arguments
    # If arity > 1, it accepts multiple arguments
    # If arity == 1, it only accepts the response
    arity = strategy.method(:parse).arity
    arity != 1
  end

  # Calls the parse method with appropriate arguments based on the strategy's signature
  # @param strategy [Object] The strategy object
  # @param response [String] The LLM response to parse
  # @param context [Hash] Optional context information
  # @return [Object] The result of the strategy's parse method
  def self.call_parse(strategy, response, context = nil)
    if accepts_context?(strategy)
      strategy.parse(response, context)
    else
      strategy.parse(response)
    end
  end
end

# For backward compatibility, delegating to StrategyConfigurationHelper
module LLMConfigurationHelper
  # Forward calls to StrategyConfigurationHelper
  def self.accepts_context?(strategy)
    StrategyConfigurationHelper.accepts_context?(strategy)
  end

  # Forward calls to StrategyConfigurationHelper
  def self.call_parse(strategy, response, context = nil)
    StrategyConfigurationHelper.call_parse(strategy, response, context)
  end
end
