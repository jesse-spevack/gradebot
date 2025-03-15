require "test_helper"

class ListGradingTaskCostsCommandTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)

    # Clear existing grading tasks and cost logs
    GradingTask.destroy_all
    LLMCostLog.destroy_all

    # Create grading tasks with different dates
    @old_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Old assignment",
      grading_rubric: "Old rubric",
      folder_id: "folder_old",
      folder_name: "Old Folder",
      created_at: 30.days.ago
    )

    @middle_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Middle assignment",
      grading_rubric: "Middle rubric",
      folder_id: "folder_middle",
      folder_name: "Middle Folder",
      created_at: 15.days.ago
    )

    @recent_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Recent assignment",
      grading_rubric: "Recent rubric",
      folder_id: "folder_recent",
      folder_name: "Recent Folder",
      created_at: 5.days.ago
    )

    # Create cost logs for each task
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

    # Create a submission for the middle task with its own cost
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
    command = ListGradingTaskCostsCommand.new(
      start_date: 100.days.ago,
      end_date: 50.days.ago
    )
    result = command.call

    assert result.success?
    assert_empty result.result
  end

  test "returns grading tasks with costs in specified date range" do
    command = ListGradingTaskCostsCommand.new(
      start_date: 20.days.ago,
      end_date: 1.day.ago
    )
    result = command.call

    assert result.success?
    assert_equal 2, result.result.length

    # Tasks should be ordered from most recent to oldest
    assert_equal @recent_task, result.result[0].grading_task
    assert_equal 0.10, result.result[0].cost

    assert_equal @middle_task, result.result[1].grading_task
    assert_equal 0.25, result.result[1].cost # 0.20 + 0.05 from submission
  end

  test "returns all grading tasks when no date range specified" do
    command = ListGradingTaskCostsCommand.new
    result = command.call

    assert result.success?
    assert_equal 3, result.result.length

    # Tasks should be ordered from most recent to oldest
    assert_equal @recent_task, result.result[0].grading_task
    assert_equal @middle_task, result.result[1].grading_task
    assert_equal @old_task, result.result[2].grading_task
  end

  test "handles invalid date range" do
    command = ListGradingTaskCostsCommand.new(
      start_date: 1.day.ago,
      end_date: 10.days.ago
    )
    result = command.call

    assert result.failure?
    assert_match /invalid date range/i, result.errors.first
  end
end
