require "test_helper"

class Rubric::StatusManagerServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @rubric = rubrics(:essay_rubric)
  end

  test "transitions from pending to processing successfully" do
    # Setup
    @rubric.update!(status: :pending)

    # Exercise
    result = Rubric::StatusManagerService.transition_to_processing(@rubric)

    # Verify
    assert result
    @rubric.reload
    assert_equal "processing", @rubric.status
  end

  test "transitions from processing to complete successfully" do
    # Setup
    @rubric.update!(status: :processing)

    # Exercise
    result = Rubric::StatusManagerService.transition_to_complete(@rubric)

    # Verify
    assert result
    @rubric.reload
    assert_equal "complete", @rubric.status
  end

  test "transitions from processing to failed successfully" do
    # Setup
    @rubric.update!(status: :processing)

    # Exercise
    result = Rubric::StatusManagerService.transition_to_failed(@rubric, "Test error message")

    # Verify
    assert result
    @rubric.reload
    assert_equal "failed", @rubric.status
  end

  test "transitions from failed to pending successfully" do
    # Setup
    @rubric.update!(status: :failed)

    # Exercise
    result = Rubric::StatusManagerService.transition_to_pending(@rubric)

    # Verify
    assert result
    @rubric.reload
    assert_equal "pending", @rubric.status
  end

  test "prevents invalid transition from pending to complete" do
    # Setup
    @rubric.update!(status: :pending)

    # Exercise & Verify
    assert_raises(Rubric::StatusManagerService::InvalidTransitionError) do
      Rubric::StatusManagerService.transition_to_complete(@rubric)
    end

    # Verify the status wasn't changed
    @rubric.reload
    assert_equal "pending", @rubric.status
  end

  test "prevents invalid transition from complete to failed" do
    # Setup
    @rubric.update!(status: :complete)

    # Exercise & Verify
    assert_raises(Rubric::StatusManagerService::InvalidTransitionError) do
      Rubric::StatusManagerService.transition_to_failed(@rubric)
    end

    # Verify the status wasn't changed
    @rubric.reload
    assert_equal "complete", @rubric.status
  end

  test "prevents invalid transition from failed to complete" do
    # Setup
    @rubric.update!(status: :failed)

    # Exercise & Verify
    assert_raises(Rubric::StatusManagerService::InvalidTransitionError) do
      Rubric::StatusManagerService.transition_to_complete(@rubric)
    end

    # Verify the status wasn't changed
    @rubric.reload
    assert_equal "failed", @rubric.status
  end

  test "allows transition to the same status" do
    # Setup
    @rubric.update!(status: :complete)

    # Exercise
    result = Rubric::StatusManagerService.transition_to_complete(@rubric)

    # Verify
    assert result
    @rubric.reload
    assert_equal "complete", @rubric.status
  end

  test "handles nil rubric gracefully" do
    # Exercise
    result = Rubric::StatusManagerService.transition_to_complete(nil)

    # Verify
    assert_not result
  end
end
