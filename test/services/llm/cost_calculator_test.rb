# frozen_string_literal: true

require "test_helper"

module LLM
  class CostCalculatorTest < ActiveSupport::TestCase
    setup do
      # Clear any existing configs and create test configs
      LLMPricingConfig.delete_all

      # Create test pricing configs
      LLMPricingConfig.create!(
        llm_model_name: "claude-3-opus",
        prompt_rate: 15.0,
        completion_rate: 75.0
      )

      LLMPricingConfig.create!(
        llm_model_name: "claude-3-sonnet",
        prompt_rate: 3.0,
        completion_rate: 15.0
      )

      LLMPricingConfig.create!(
        llm_model_name: "default",
        prompt_rate: 10.0,
        completion_rate: 30.0
      )
    end

    test "calculates cost correctly for Claude 3 Opus" do
      # Setup
      prompt_tokens = 1000
      completion_tokens = 500

      # Exercise
      cost = CostCalculator.calculate("claude-3-opus", prompt_tokens, completion_tokens)

      # Verify - with calculation using millions of tokens
      expected_prompt_cost = (1000 * 15.0/1000000)
      expected_completion_cost = (500 * 75.0/1000000)
      expected_total_cost = expected_prompt_cost + expected_completion_cost

      assert_equal expected_prompt_cost.round(6), cost[:prompt_cost].round(6)
      assert_equal expected_completion_cost.round(6), cost[:completion_cost].round(6)
      assert_equal expected_total_cost.round(6), cost[:total_cost].round(6)
    end

    test "uses default rates for unknown models" do
      # Setup
      prompt_tokens = 1000
      completion_tokens = 500

      # Exercise
      cost = CostCalculator.calculate("unknown-model", prompt_tokens, completion_tokens)

      # Verify - with calculation using millions of tokens
      expected_prompt_cost = (1000 * 10.0/1000000)
      expected_completion_cost = (500 * 30.0/1000000)
      expected_total_cost = expected_prompt_cost + expected_completion_cost

      assert_equal expected_prompt_cost.round(6), cost[:prompt_cost].round(6)
      assert_equal expected_completion_cost.round(6), cost[:completion_cost].round(6)
      assert_equal expected_total_cost.round(6), cost[:total_cost].round(6)
    end

    test "handles zero tokens gracefully" do
      # Setup
      prompt_tokens = 0
      completion_tokens = 0

      # Exercise
      cost = CostCalculator.calculate("claude-3-sonnet", prompt_tokens, completion_tokens)

      # Verify
      assert_equal 0.0, cost[:prompt_cost]
      assert_equal 0.0, cost[:completion_cost]
      assert_equal 0.0, cost[:total_cost]
    end

    test "get_rates_for_model returns rates from database" do
      rates = CostCalculator.get_rates_for_model("claude-3-opus")

      assert_equal 15.0, rates[:prompt]
      assert_equal 75.0, rates[:completion]
    end

    test "pricing_rates returns rates from database" do
      rates = CostCalculator.pricing_rates

      assert_includes rates.keys, "claude-3-opus"
      assert_includes rates.keys, "claude-3-sonnet"
      assert_includes rates.keys, "default"

      claude_opus_rates = rates["claude-3-opus"]
      assert_equal 15.0, claude_opus_rates[:prompt]
      assert_equal 75.0, claude_opus_rates[:completion]
    end

    test "default_rate returns rate from database" do
      rate = CostCalculator.default_rate

      assert_equal 10.0, rate[:prompt]
      assert_equal 30.0, rate[:completion]
    end

    test "fallback to hardcoded default if database default missing" do
      # Delete the default config
      LLMPricingConfig.find_by(llm_model_name: "default").destroy

      rate = CostCalculator.default_rate

      assert_equal 10.0, rate[:prompt]
      assert_equal 30.0, rate[:completion]
    end
  end
end
