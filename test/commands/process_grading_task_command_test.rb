require "test_helper"

class ProcessGradingTaskCommandTest < ActiveJob::TestCase
  # Setup
  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)

    # Clear existing submissions for the grading task
    StudentSubmission.where(grading_task: @grading_task).delete_all
  end

  test "enqueues formatting jobs" do
    # Setup
    # Expect formatting jobs to be enqueued
    assert_enqueued_with(job: FormatAssignmentPromptJob, args: [ @grading_task.id ]) do
      # Exercise
      command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id)
      result = command.execute

      # Verify
      assert_equal @grading_task, result
      assert_empty command.errors
      assert_equal "assignment_processing", @grading_task.reload.status
    end
  end

  test "handles errors gracefully" do
    # Setup
    # Mock the grading task to raise an error when start_assignment_processing! is called
    mock_grading_task = mock("GradingTask")
    mock_grading_task.stubs(:start_assignment_processing!).raises(StandardError.new("Failed to start processing"))
    mock_grading_task.stubs(:fail!).returns(true)
    mock_grading_task.stubs(:id).returns(@grading_task.id)
    mock_grading_task.stubs(:display_name).returns("Test Folder")

    GradingTask.stubs(:find_by).with(id: @grading_task.id).returns(mock_grading_task)

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id)
    result = command.execute

    # Verify
    assert_nil result
    assert_includes command.errors, "Failed to start processing"
  end

  test "returns nil when grading task is not found" do
    # Setup
    GradingTask.destroy_all

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: 12345)
    result = command.execute

    # Verify
    assert_nil result
    assert_includes command.errors, "Grading task not found with ID: 12345"
  end

  test "enqueues_jobs_in_the_correct_sequence" do
    # Setup
    grading_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Test assignment",
      grading_rubric: "Test rubric",
      status: "created"
    )

    # Execute
    assert_enqueued_with(job: FormatAssignmentPromptJob, args: [ grading_task.id ]) do
      ProcessGradingTaskCommand.new(grading_task_id: grading_task.id).execute
    end

    # Verify the grading task state
    grading_task.reload
    assert_equal "assignment_processing", grading_task.status

    # FormatGradingRubricJob and StudentSubmissionsForGradingTaskJob should not be enqueued yet
    assert_no_enqueued_jobs(only: FormatGradingRubricJob)
    assert_no_enqueued_jobs(only: StudentSubmissionsForGradingTaskJob)
  end
end
