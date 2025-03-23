require "test_helper"

class GetGoogleDriveClientForStudentSubmissionCommandTest < ActiveSupport::TestCase
  test "it creates student submissions" do
    student_submission = student_submissions(:pending_submission)
    drive_client = mock("drive_client")
    token_service = mock("token_service")

    TokenService.expects(:new).with(student_submission.grading_task.user).returns(token_service)
    token_service.expects(:create_google_drive_client).returns(drive_client)

    command = GetGoogleDriveClientForStudentSubmissionCommand.call(
      student_submission: student_submission
    )

    assert command.success?
    assert_equal command.result, drive_client
  end
end
