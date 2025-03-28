require "test_helper"

class DocumentAction::PostFeedbackServiceTest < ActiveSupport::TestCase
  test "posts feedback to the document correctly" do
    # Setup
    student_submission = student_submissions(:completed_submission)
    document_action = DocumentAction.new(
      student_submission: student_submission,
      action_type: :post_feedback,
      status: :processing
    )

    # Create service with stubbed google_docs_client method
    service = DocumentAction::PostFeedbackService.new(document_action)
    mock_google_docs_client = mock("GoogleDocsClient")
    service.stubs(:google_docs_client).returns(mock_google_docs_client)

    # Mock the document content appender service
    mock_appender_service = mock("DocumentContentAppenderService")
    mock_appender_service.expects(:append).with(student_submission.feedback).returns(true)

    ::DocumentContentAppenderService.expects(:new)
      .with(
        document_id: student_submission.original_doc_id,
        google_docs_client: mock_google_docs_client
      )
      .returns(mock_appender_service)

    # Also stub the class method to return our instance with stubbed methods
    DocumentAction::PostFeedbackService.stubs(:new).with(document_action).returns(service)

    # Exercise
    result = DocumentAction::PostFeedbackService.post(document_action)

    # Verify
    assert_equal true, result
  end

  test "initializes with document action" do
    # Setup
    document_action = DocumentAction.new(
      student_submission: student_submissions(:completed_submission),
      action_type: :post_feedback
    )

    # Exercise
    service = DocumentAction::PostFeedbackService.new(document_action)

    # Verify
    assert_equal document_action, service.document_action
    assert_equal document_action.student_submission, service.student_submission
  end

  test "self.post delegates to instance post method" do
    # Setup
    document_action = DocumentAction.new(
      student_submission: student_submissions(:completed_submission),
      action_type: :post_feedback
    )

    mock_service = mock("PostFeedbackService")
    mock_service.expects(:post).returns(true)

    DocumentAction::PostFeedbackService.expects(:new)
      .with(document_action)
      .returns(mock_service)

    # Exercise & Verify
    assert_equal true, DocumentAction::PostFeedbackService.post(document_action)
  end
end
