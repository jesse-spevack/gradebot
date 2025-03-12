require "test_helper"
require "minitest/mock"

class StudentSubmissionJobTest < ActiveJob::TestCase
  # Setup
  setup do
    @student_submission = student_submissions(:pending_submission)
  end

  test "calls process command with submission id" do
    # Setup
    command_mock = mock("Command")
    command_mock.stubs(:call).returns(command_mock)
    command_mock.stubs(:failure?).returns(false)

    # Exercise - verify the command is called with the right ID
    ProcessStudentSubmissionCommand.expects(:new).with(student_submission_id: @student_submission.id).returns(command_mock)

    # Mock RetryHandler to avoid complexity
    RetryHandler.stubs(:with_retry).yields

    # Run the job
    StudentSubmissionJob.perform_now(@student_submission.id)
  end

  test "marks submission as failed on unhandled errors" do
    # Setup
    error = StandardError.new("Test error")

    # Mock the command to raise an error
    ProcessStudentSubmissionCommand.stubs(:new).raises(error)

    # Mock RetryHandler to re-raise the error
    RetryHandler.stubs(:with_retry).raises(error)

    # Silence logging
    Rails.logger.stubs(:error)

    # Verify the submission is marked as failed
    StatusManager.expects(:transition_submission).with(
      @student_submission,
      :failed,
      has_entry(feedback: includes("Failed to complete grading"))
    ).returns(true)

    # Run the job
    StudentSubmissionJob.perform_now(@student_submission.id)
  end

  private

  # Helper to verify log messages
  def assert_logged(level:, message:)
    old_logger = Rails.logger
    begin
      mock_logger = Minitest::Mock.new
      mock_logger.expect(level, nil) do |msg, _|
        assert_match message, msg
        true
      end
      Rails.logger = mock_logger
      yield
      assert_mock mock_logger
    ensure
      Rails.logger = old_logger
    end
  end
end
