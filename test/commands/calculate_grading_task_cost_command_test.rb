require "test_helper"

class CalculateGradingTaskCostCommandTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)

    # Clear existing cost logs for this grading task
    LLMCostLog.where(trackable: @grading_task).delete_all

    # Clear cost logs for any submissions related to this task
    @grading_task.student_submissions.each do |submission|
      LLMCostLog.where(trackable: submission).delete_all
    end
  end

  test "returns zero when no costs exist" do
    command = CalculateGradingTaskCostCommand.new(grading_task: @grading_task)
    result = command.call

    assert result.success?
    assert_equal 0, result.result
  end

  test "calculates total cost from multiple logs" do
    # Create some cost logs for the grading task
    LLMCostLog.create!(
      trackable: @grading_task,
      llm_model_name: "claude-3-opus",
      cost: 0.15,
      request_type: "grading"
    )

    LLMCostLog.create!(
      trackable: @grading_task,
      llm_model_name: "claude-3-sonnet",
      cost: 0.05,
      request_type: "grading"
    )

    LLMCostLog.create!(
      trackable: @grading_task,
      llm_model_name: "gpt-4",
      cost: 0.10,
      request_type: "summarization"
    )

    command = CalculateGradingTaskCostCommand.new(grading_task: @grading_task)
    result = command.call

    assert result.success?
    assert_equal 0.30, result.result
  end

  test "handles invalid grading task" do
    command = CalculateGradingTaskCostCommand.new(grading_task: "not a grading task")
    result = command.call

    assert result.failure?
    assert_match /Invalid grading task/, result.errors.first
  end

  test "includes costs from student submissions" do
    # Create a student submission for the grading task
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "test_doc_123",
      status: :pending
    )

    # Reload the grading task to ensure it has the latest student submissions
    @grading_task.reload

    # Create cost logs for both the grading task and its submission
    LLMCostLog.create!(
      trackable: @grading_task,
      llm_model_name: "claude-3-opus",
      cost: 0.15,
      request_type: "grading"
    )

    LLMCostLog.create!(
      trackable: submission,
      llm_model_name: "claude-3-sonnet",
      cost: 0.05,
      request_type: "grading"
    )

    # We include costs from both the grading task and its submissions
    command = CalculateGradingTaskCostCommand.new(grading_task: @grading_task)
    result = command.call

    assert result.success?
    assert_equal 0.20, result.result
  end
end
