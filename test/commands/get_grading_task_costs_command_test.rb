require "test_helper"

class GetGradingTaskCostsCommandTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)

    GradingTask.destroy_all
    LLMCostLog.destroy_all

    @old_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Old assignment",
      grading_rubric: "Old rubric",
      created_at: 30.days.ago
    )

    @middle_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Middle assignment",
      grading_rubric: "Middle rubric",
      created_at: 15.days.ago
    )

    @recent_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Recent assignment",
      grading_rubric: "Recent rubric",
      created_at: 5.days.ago
    )

    LLMCostLog.create!(
      trackable: @old_task,
      llm_model_name: "claude-3-opus",
      cost: 0.30,
      request_type: "grading",
      created_at: 29.days.ago
    )

    LLMCostLog.create!(
      trackable: @middle_task,
      llm_model_name: "claude-3-sonnet",
      cost: 0.20,
      request_type: "grading",
      created_at: 14.days.ago
    )

    LLMCostLog.create!(
      trackable: @recent_task,
      llm_model_name: "gpt-4",
      cost: 0.10,
      request_type: "grading",
      created_at: 4.days.ago
    )

    @submission = StudentSubmission.create!(
      grading_task: @middle_task,
      original_doc_id: "test_doc_123",
      status: :completed,
      created_at: 14.days.ago
    )

    LLMCostLog.create!(
      trackable: @submission,
      llm_model_name: "claude-3-haiku",
      cost: 0.05,
      request_type: "grading",
      created_at: 14.days.ago
    )
  end

  test "returns empty array when no grading tasks exist in date range" do
    command = GetGradingTaskCostsCommand.call(
      start_date: 100.days.ago,
      end_date: 50.days.ago
    )

    assert command.success?
    assert_empty command.result
  end

  test "returns grading tasks with costs in specified date range" do
    command = GetGradingTaskCostsCommand.call(
      start_date: 20.days.ago,
      end_date: 1.day.ago
    )

    assert command.success?
    assert_equal 2, command.result.length

    # Tasks should be ordered from most recent to oldest
    assert_equal @recent_task, command.result[0].grading_task
    assert_equal 0.10, command.result[0].cost

    assert_equal @middle_task, command.result[1].grading_task
    assert_equal 0.25, command.result[1].cost # 0.20 + 0.05 from submission
  end

  test "returns all grading tasks when no date range specified" do
    command = GetGradingTaskCostsCommand.call
    assert command.success?
    assert_equal 3, command.result.length

    # Tasks should be ordered from most recent to oldest
    assert_equal @recent_task, command.result[0].grading_task
    assert_equal @middle_task, command.result[1].grading_task
    assert_equal @old_task, command.result[2].grading_task
  end

  test "handles invalid date range" do
    command = GetGradingTaskCostsCommand.call(
      start_date: 1.day.ago,
      end_date: 10.days.ago
    )

    assert command.failure?
    assert_match /invalid date range/i, command.errors.first
  end
end
