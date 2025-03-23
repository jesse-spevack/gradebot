require "test_helper"

class StudentSubmission::StatusUpdaterTest < ActiveSupport::TestCase
  setup do
    @student_submission = mock("StudentSubmission")
    @student_submission.stubs(:id).returns(123)
    @student_submission.stubs(:reload).returns(@student_submission)
  end

  test "initializes with a submission" do
    updater = StudentSubmission::StatusUpdater.new(@student_submission)

    assert_equal @student_submission, updater.instance_variable_get(:@student_submission)
  end

  test "transitions submission to processing state" do
    StatusManager.expects(:transition_submission).with(@student_submission, :processing, {}).returns(true)

    StudentSubmission::StatusUpdater.transition_student_submission_to_processing(@student_submission)
  end

  test "transitions submission to completed state with attributes" do
    attributes = {
      feedback: "Great job!",
      overall_grade: "A"
    }

    StatusManager.expects(:transition_submission).with(@student_submission, :completed, attributes).returns(true)

    StudentSubmission::StatusUpdater.transition_student_submission_to_completed(@student_submission, attributes)
  end

  test "transitions submission to failed state with error message" do
    attributes = {
      feedback: "Processing failed: Error message"
    }

    StatusManager.expects(:transition_submission).with(@student_submission, :failed, attributes).returns(true)

    StudentSubmission::StatusUpdater.transition_student_submission_to_failed(@student_submission, attributes)
  end
end
