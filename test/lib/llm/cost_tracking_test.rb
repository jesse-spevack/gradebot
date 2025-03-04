require "test_helper"

class LLM::CostTrackingTest < ActiveSupport::TestCase
  test "calculates cost correctly for Claude 3 Opus" do
    # Setup
    prompt_tokens = 1000
    completion_tokens = 500

    # Exercise
    cost = LLM::CostTracking.calculate_cost("claude-3-opus", prompt_tokens, completion_tokens)

    # Verify
    expected = (1000 * 15.0/1000) + (500 * 75.0/1000)
    assert_equal expected.round(6), cost
  end

  test "uses default rates for unknown models" do
    # Setup
    prompt_tokens = 1000
    completion_tokens = 500

    # Exercise
    cost = LLM::CostTracking.calculate_cost("unknown-model", prompt_tokens, completion_tokens)

    # Verify
    expected = (1000 * 10.0/1000) + (500 * 30.0/1000)
    assert_equal expected.round(6), cost
  end

  test "handles zero tokens gracefully" do
    # Setup
    prompt_tokens = 0
    completion_tokens = 0

    # Exercise
    cost = LLM::CostTracking.calculate_cost("claude-3-sonnet", prompt_tokens, completion_tokens)

    # Verify
    assert_equal 0.0, cost
  end

  test "generates complete context with all parameters" do
    # Setup
    user = users(:teacher)
    submission = student_submissions(:pending_submission)

    # Exercise
    context = LLM::CostTracking.generate_context(
      request_type: "test",
      trackable: submission,
      user: user,
      metadata: { custom: "value" }
    )

    # Verify
    refute_nil context[:request_id]
    assert_equal "test", context[:request_type]
    assert_equal submission, context[:trackable]
    assert_equal user, context[:user]
    assert_equal({ custom: "value" }, context[:metadata])
  end

  test "generates uuid for request_id" do
    # Exercise
    context = LLM::CostTracking.generate_context

    # Verify
    assert_match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, context[:request_id])
  end

  test "handles nil parameters in context generation" do
    # Exercise
    context = LLM::CostTracking.generate_context

    # Verify
    assert_nil context[:request_type]
    assert_nil context[:trackable]
    assert_nil context[:user]
    assert_equal({}, context[:metadata])
  end

  test "creates cost log record with full data" do
    # Setup
    cost_data = {
      llm_model_name: "claude-3-sonnet",
      prompt_tokens: 100,
      completion_tokens: 50,
      total_tokens: 150,
      cost: 0.00225
    }

    context = LLM::CostTracking.generate_context(
      request_type: "test",
      user: users(:teacher)
    )

    # Exercise
    assert_difference -> { LlmCostLog.count }, 1 do
      LLM::CostTracking.record(cost_data, context)
    end

    # Verify
    log = LlmCostLog.last
    assert_equal users(:teacher), log.user
    assert_equal "test", log.request_type
    assert_equal "claude-3-sonnet", log.llm_model_name
    assert_equal 100, log.prompt_tokens
    assert_equal 50, log.completion_tokens
    assert_equal 150, log.total_tokens
    assert_equal 0.00225, log.cost
  end

  test "works with minimal data" do
    # Setup
    minimal_data = { llm_model_name: "claude-3-haiku", cost: 0.001 }

    # Exercise
    assert_difference -> { LlmCostLog.count }, 1 do
      LLM::CostTracking.record(minimal_data)
    end

    # Verify
    log = LlmCostLog.last
    assert_equal "claude-3-haiku", log.llm_model_name
    assert_equal 0.001, log.cost
  end

  test "logs errors but does not raise them" do
    # Setup
    cost_data = { llm_model_name: "claude-3-sonnet", cost: 0.001 }
    context = { request_type: "test" }

    Rails.logger.expects(:error).with(regexp_matches(/Failed to record LLM cost/))

    # Create a temporary replacement for the create! method that raises an error
    LlmCostLog.stub :create!, ->(*args) { raise "Database error" } do
      # Exercise & Verify - should not raise error
      assert_nothing_raised do
        LLM::CostTracking.record(cost_data, context)
      end
    end
  end
end
