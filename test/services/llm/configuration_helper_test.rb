# frozen_string_literal: true

require "test_helper"

module LLM
  class ConfigurationHelperTest < ActiveSupport::TestCase
    class SimpleStrategy
      def parse(response)
        { result: response }
      end
    end

    class ContextAwareStrategy
      def parse(response, context)
        { result: response, context: context }
      end
    end

    test "accepts_context? returns false for strategies with one parameter" do
      strategy = SimpleStrategy.new
      assert_not ConfigurationHelper.accepts_context?(strategy)
    end

    test "accepts_context? returns true for strategies with multiple parameters" do
      strategy = ContextAwareStrategy.new
      assert ConfigurationHelper.accepts_context?(strategy)
    end

    test "call_parse handles strategies without context parameter" do
      strategy = SimpleStrategy.new
      response = "test response"
      context = { test: true }

      result = ConfigurationHelper.call_parse(strategy, response, context)
      assert_equal({ result: response }, result)
    end

    test "call_parse handles strategies with context parameter" do
      strategy = ContextAwareStrategy.new
      response = "test response"
      context = { test: true }

      result = ConfigurationHelper.call_parse(strategy, response, context)
      assert_equal({ result: response, context: context }, result)
    end
  end
end
