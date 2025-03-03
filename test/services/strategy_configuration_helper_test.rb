# frozen_string_literal: true

require "test_helper"

class TestSingleArgStrategy
  def parse(response)
    { parsed: response }
  end
end

class TestMultiArgStrategy
  def parse(response, context = nil)
    { parsed: response, context: context }
  end
end

class StrategyConfigurationHelperTest < ActiveSupport::TestCase
  setup do
    @single_arg_strategy = TestSingleArgStrategy.new
    @multi_arg_strategy = TestMultiArgStrategy.new
    @response = "test response"
    @context = { test: "context" }
  end

  test "accepts_context? returns false for strategy with single argument" do
    assert_not StrategyConfigurationHelper.accepts_context?(@single_arg_strategy)
  end

  test "accepts_context? returns true for strategy with multiple arguments" do
    assert StrategyConfigurationHelper.accepts_context?(@multi_arg_strategy)
  end

  test "call_parse passes only response to single arg strategy" do
    result = StrategyConfigurationHelper.call_parse(@single_arg_strategy, @response, @context)
    assert_equal({ parsed: @response }, result)
  end

  test "call_parse passes response and context to multi arg strategy" do
    result = StrategyConfigurationHelper.call_parse(@multi_arg_strategy, @response, @context)
    assert_equal({ parsed: @response, context: @context }, result)
  end
end
