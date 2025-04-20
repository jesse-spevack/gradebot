require "test_helper"

class GradingTask::StatusManagerServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:three)
  end

  test "transitions from created to processing successfully" do
    # Exercise
    result = GradingTask::StatusManagerService.transition_to_processing(@grading_task)

    # Verify
    assert result
    @grading_task.reload
    assert_equal "processing", @grading_task.status
  end

  test "transitions from processing to completed successfully" do
    # Setup
    @grading_task.update!(status: :processing)

    # Exercise
    result = GradingTask::StatusManagerService.transition_to_completed(@grading_task)

    # Verify
    assert result
    @grading_task.reload
    assert_equal "completed", @grading_task.status
  end

  test "transitions from processing to failed successfully" do
    # Setup
    @grading_task.update!(status: :processing)

    # Exercise
    result = GradingTask::StatusManagerService.transition_to_failed(@grading_task, "Test error message")

    # Verify
    assert result
    @grading_task.reload
    assert_equal "failed", @grading_task.status
  end

  test "transitions from failed to created successfully" do
    # Setup
    @grading_task.update!(status: :failed)

    # Exercise
    result = GradingTask::StatusManagerService.transition_to_pending(@grading_task)

    # Verify
    assert result
    @grading_task.reload
    assert_equal "pending", @grading_task.status
  end

  test "prevents invalid transition from created to completed" do
    # Exercise & Verify
    assert_raises(GradingTask::StatusManagerService::InvalidTransitionError) do
      GradingTask::StatusManagerService.transition_to_completed(@grading_task)
    end

    # Verify the status wasn't changed
    @grading_task.reload
    assert_equal "pending", @grading_task.status
  end

  test "prevents invalid transition from pending to failed" do
    # Setup
    @grading_task.update!(status: :pending)

    # Exercise & Verify
    assert_raises(GradingTask::StatusManagerService::InvalidTransitionError) do
      GradingTask::StatusManagerService.transition_to_failed(@grading_task)
    end

    # Verify the status wasn't changed
    @grading_task.reload
    assert_equal "pending", @grading_task.status
  end

  test "prevents invalid transition from completed to processing" do
    # Setup
    @grading_task.update!(status: :completed)

    # Exercise & Verify
    assert_raises(GradingTask::StatusManagerService::InvalidTransitionError) do
      GradingTask::StatusManagerService.transition_to_processing(@grading_task)
    end

    # Verify the status wasn't changed
    @grading_task.reload
    assert_equal "completed", @grading_task.status
  end

  test "prevents invalid transition from failed to completed" do
    # Setup
    @grading_task.update!(status: :failed)

    # Exercise & Verify
    assert_raises(GradingTask::StatusManagerService::InvalidTransitionError) do
      GradingTask::StatusManagerService.transition_to_completed(@grading_task)
    end

    # Verify the status wasn't changed
    @grading_task.reload
    assert_equal "failed", @grading_task.status
  end

  test "allows transition to the same status" do
    # Setup
    @grading_task.update!(status: :completed)

    # Exercise
    result = GradingTask::StatusManagerService.transition_to_completed(@grading_task)

    # Verify
    assert result
    @grading_task.reload
    assert_equal "completed", @grading_task.status
  end

  test "handles nil grading_task gracefully" do
    # Exercise
    result = GradingTask::StatusManagerService.transition_to_completed(nil)

    # Verify
    assert_not result
  end


  test "provides display labels for statuses" do
    # Verify
    assert_equal "Created", GradingTask::StatusManagerService.label_for(:created)
    assert_equal "Processing", GradingTask::StatusManagerService.label_for(:processing)
    assert_equal "Completed", GradingTask::StatusManagerService.label_for(:completed)
    assert_equal "Failed", GradingTask::StatusManagerService.label_for(:failed)
    assert_equal "Unknown", GradingTask::StatusManagerService.label_for(:unknown)
  end
end
