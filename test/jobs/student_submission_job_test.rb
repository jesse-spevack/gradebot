# frozen_string_literal: true

require "test_helper"

class StudentSubmissionJobTest < ActiveJob::TestCase
  # Setup
  setup do
    @submission = student_submissions(:pending_submission)
    @submission.update(status: "pending")
  end

  test "processes a student submission" do
    # Using Object.new for mocking instead of Minitest::Mock because:
    # 1. We only need to define a few simple methods
    # 2. We don't need to verify method calls with specific arguments
    # 3. The object is used in equality comparisons (assert_equal)
    mock_command = Object.new
    def mock_command.call; self; end
    def mock_command.failure?; false; end

    # Stub the command class
    ProcessStudentSubmissionCommand.stubs(:new).returns(mock_command)

    # Perform the job
    result = StudentSubmissionJob.perform_now(@submission.id)

    # Verify the result is the command
    assert_equal mock_command, result
  end

  test "handles command failure" do
    # Create a mock command using Object.new for simplicity
    mock_command = Object.new
    def mock_command.call; self; end
    def mock_command.failure?; true; end
    def mock_command.errors; [ "Test error" ]; end

    # Stub the command class
    ProcessStudentSubmissionCommand.stubs(:new).returns(mock_command)

    # Perform the job
    result = StudentSubmissionJob.perform_now(@submission.id)

    # Verify the result is the command
    assert_equal mock_command, result
  end

  test "handles unhandled errors" do
    error = StandardError.new("Test error")

    # Stub the command class to raise an error
    ProcessStudentSubmissionCommand.stub :new, ->(*args) { raise error } do
      # Stub StatusManager to verify it's called
      StatusManager.stub :transition_submission, true do
        # Perform the job
        result = StudentSubmissionJob.perform_now(@submission.id)

        # Should return nil on error
        assert_nil result
      end
    end
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
