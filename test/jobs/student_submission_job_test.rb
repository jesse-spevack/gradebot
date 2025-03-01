require "test_helper"
require "minitest/mock"

class StudentSubmissionJobTest < ActiveJob::TestCase
  # Setup
  setup do
    @student_submission = student_submissions(:pending_submission)
  end

  test "job calls ProcessStudentSubmissionCommand with submission id" do
    # Setup
    command_mock = Minitest::Mock.new
    command_mock.expect(:call, command_mock)
    command_mock.expect(:failure?, false)

    # Exercise
    ProcessStudentSubmissionCommand.stub(:new, ->(student_submission_id:) {
      assert_equal @student_submission.id, student_submission_id
      command_mock
    }) do
      StudentSubmissionJob.perform_now(@student_submission.id)
    end

    # Verify
    assert_mock command_mock
  end

  test "logs error if command fails" do
    # Setup
    command_mock = Minitest::Mock.new
    command_mock.expect(:call, command_mock)
    command_mock.expect(:failure?, true)
    command_mock.expect(:errors, [ "Failed to process student submission" ])

    # Exercise & Verify
    ProcessStudentSubmissionCommand.stub(:new, ->(**) { command_mock }) do
      assert_logged(level: :error, message: /StudentSubmissionJob failed/) do
        StudentSubmissionJob.perform_now(@student_submission.id)
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
