require "test_helper"

class GetGoogleDocsClientForStudentSubmissionCommandTest < ActiveSupport::TestCase
  test "it creates student submissions" do
    student_submission = student_submissions(:pending_submission)
    docs_client = mock("docs_client")
    token_service = mock("token_service")

    TokenService.expects(:new).with(student_submission.grading_task.user).returns(token_service)
    token_service.expects(:create_google_docs_client).returns(docs_client)

    command = GetGoogleDocsClientForStudentSubmissionCommand.call(
      student_submission: student_submission
    )

    assert command.success?
    assert_equal command.result, docs_client
  end
end
