require "test_helper"

class SubmissionStatusUpdaterTest < ActiveSupport::TestCase
  setup do
    # Create a mock submission instead of using fixture
    @submission = mock("StudentSubmission")
    @submission.stubs(:id).returns(123)
  end

  test "initializes with a submission" do
    # Setup
    updater = SubmissionStatusUpdater.new(@submission)

    # Verify
    assert_equal @submission, updater.instance_variable_get(:@submission)
  end

  test "transitions submission to processing state" do
    # Setup
    updater = SubmissionStatusUpdater.new(@submission)
    StatusManager.expects(:transition_submission).with(@submission, :processing, {}).returns(true)

    # Exercise
    result = updater.transition_to(:processing)

    # Verify
    assert result
  end

  test "transitions submission to completed state with attributes" do
    # Setup
    updater = SubmissionStatusUpdater.new(@submission)
    attributes = {
      feedback: "Great job!",
      overall_grade: "A"
    }
    StatusManager.expects(:transition_submission).with(@submission, :completed, attributes).returns(true)

    # Exercise
    result = updater.transition_to(:completed, attributes)

    # Verify
    assert result
  end

  test "transitions submission to failed state with error message" do
    # Setup
    updater = SubmissionStatusUpdater.new(@submission)
    attributes = {
      feedback: "Processing failed: Error message"
    }
    StatusManager.expects(:transition_submission).with(@submission, :failed, attributes).returns(true)

    # Exercise
    result = updater.transition_to(:failed, attributes)

    # Verify
    assert result
  end

  test "handles transition failure gracefully" do
    # Setup
    updater = SubmissionStatusUpdater.new(@submission)
    StatusManager.expects(:transition_submission).with(@submission, :processing, {}).raises(StandardError.new("Transition failed"))

    # Exercise
    result = updater.transition_to(:processing)

    # Verify
    assert_not result
  end
end
