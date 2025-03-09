# frozen_string_literal: true

require "test_helper"

module LLM
  class CostTrackerTest < ActiveSupport::TestCase
    test "generates complete context with all parameters" do
      # Setup
      user = users(:teacher)
      submission = student_submissions(:pending_submission)

      # Exercise
      context = CostTracker.generate_context(
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
      context = CostTracker.generate_context

      # Verify
      assert_match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, context[:request_id])
    end

    test "handles nil parameters in context generation" do
      # Exercise
      context = CostTracker.generate_context

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

      context = {
        request_type: "test",
        user: users(:teacher),
        request_id: SecureRandom.uuid
      }

      # Exercise
      assert_difference -> { LLMCostLog.count }, 1 do
        CostTracker.record(cost_data, context)
      end

      # Verify
      log = LLMCostLog.last
      assert_equal "claude-3-sonnet", log.llm_model_name
      assert_equal 100, log.prompt_tokens
      assert_equal 50, log.completion_tokens
      assert_equal 150, log.total_tokens
      assert_equal 0.00225, log.cost
      assert_equal "test", log.request_type
      assert_equal users(:teacher), log.user
    end

    test "works with minimal data" do
      # Setup
      cost_data = {
        llm_model_name: "claude-3-sonnet",
        cost: 0.00225
      }

      # Exercise
      assert_difference -> { LLMCostLog.count }, 1 do
        CostTracker.record(cost_data, {})
      end

      # Verify
      log = LLMCostLog.last
      assert_equal "claude-3-sonnet", log.llm_model_name
      assert_equal 0.00225, log.cost
      assert_nil log.request_type
      assert_nil log.user
    end

    test "logs errors but does not raise them" do
      # Setup
      cost_data = {
        llm_model_name: "claude-3-sonnet",
        cost: 0.00225
      }

      # Temporarily disable re-raising errors in test environment
      Rails.env.stubs(:test?).returns(false)

      # Exercise & Verify
      # We now have multiple error log messages, so just check that the first one is there
      Rails.logger.expects(:error).with(includes("LLM Cost Tracking - Failed to create cost log")).at_least_once

      # Stub other error logs that we don't care about for this test
      Rails.logger.stubs(:error).with(Not(includes("LLM Cost Tracking - Failed to create cost log")))

      assert_no_difference -> { LLMCostLog.count } do
        LLMCostLog.stubs(:create!).raises("Database error")
        CostTracker.record(cost_data, {})
      end

      # Restore the original behavior
      Rails.env.unstub(:test?)
    end
  end
end
