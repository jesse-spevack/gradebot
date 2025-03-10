require "test_helper"

class ProcessGradingTaskCommandTest < ActiveJob::TestCase
  # Setup
  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)
    @folder_id = @grading_task.folder_id

    # Mock document data that would be returned from Google Drive
    @mock_documents = [
      { id: "doc1", name: "Student 1 - Assignment.docx" },
      { id: "doc2", name: "Student 2 - Assignment.docx" },
      { id: "doc3", name: "Student 3 - Assignment.docx" }
    ]

    # Clear existing submissions for the grading task
    StudentSubmission.where(grading_task: @grading_task).delete_all

    # Create a more complete mock for existing tests
    @grading_task = mock("GradingTask")
    @grading_task.stubs(:id).returns(123)
    @grading_task.stubs(:folder_id).returns("folder_123")
    @grading_task.stubs(:folder_name).returns("Test Folder")
    @user = mock("User")
    @user.stubs(:id).returns(456)
    @grading_task.stubs(:user).returns(@user)

    GradingTask.stubs(:find_by).with(id: 123).returns(@grading_task)

    # Default mock documents
    @mock_documents = [
      { id: "doc1", name: "Document 1", mime_type: "application/vnd.google-apps.document" },
      { id: "doc2", name: "Document 2", mime_type: "application/vnd.google-apps.document" }
    ]

    # Create ProcessStudentSubmissionJob if it doesn't exist
    unless Object.const_defined?("ProcessStudentSubmissionJob")
      Object.const_set("ProcessStudentSubmissionJob", Class.new)
    end

    # Set up logging
    Rails.logger.stubs(:info)
    Rails.logger.stubs(:error)
  end

  test "fetches documents from Google Drive and creates submissions" do
    # Setup
    # Mock access token service
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    # Mock document fetcher
    document_fetcher = mock("FolderDocumentFetcherService")
    FolderDocumentFetcherService.stubs(:new).with("mock_access_token", "folder_123").returns(document_fetcher)
    document_fetcher.stubs(:fetch).returns(@mock_documents)

    # Mock submission creator
    submission_creator = mock("SubmissionCreatorService")
    SubmissionCreatorService.stubs(:new).with(@grading_task, @mock_documents).returns(submission_creator)
    submission_creator.stubs(:create_submissions).returns(2)

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: 123)
    result = command.execute

    # Verify
    assert_equal @grading_task, result
    assert_empty command.errors
  end

  test "enqueues jobs for processing submissions" do
    # Mock access token service
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    # Mock document fetcher
    document_fetcher = mock("FolderDocumentFetcherService")
    FolderDocumentFetcherService.stubs(:new).with("mock_access_token", "folder_123").returns(document_fetcher)
    document_fetcher.stubs(:fetch).returns(@mock_documents)

    # Set up job expectations
    ProcessStudentSubmissionJob.expects(:perform_later).with(101).once
    ProcessStudentSubmissionJob.expects(:perform_later).with(102).once

    # Create a submission creator that will trigger the job enqueuing
    creator = Object.new
    def creator.create_submissions
      # This simulates what the real implementation would do
      ProcessStudentSubmissionJob.perform_later(101)
      ProcessStudentSubmissionJob.perform_later(102)
      2 # Return count of submissions processed
    end

    SubmissionCreatorService.stubs(:new).with(@grading_task, @mock_documents).returns(creator)

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: 123)
    result = command.execute

    # Verify command succeeded
    assert_equal @grading_task, result
    assert_empty command.errors
  end

  test "handles empty folders" do
    # Setup
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    # Mock document fetcher to return empty array
    document_fetcher = mock("FolderDocumentFetcherService")
    FolderDocumentFetcherService.stubs(:new).with("mock_access_token", "folder_123").returns(document_fetcher)
    document_fetcher.stubs(:fetch).returns([])

    # Mock submission creator to return 0 submissions
    submission_creator = mock("SubmissionCreatorService")
    SubmissionCreatorService.stubs(:new).with(@grading_task, []).returns(submission_creator)
    submission_creator.stubs(:create_submissions).returns(0)

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: 123)
    result = command.execute

    # Verify
    assert_equal @grading_task, result
    assert_includes command.errors, "No submissions created from documents"
  end

  test "handles Google Drive service errors" do
    # Setup
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    # Mock document fetcher to raise an error
    document_fetcher = mock("FolderDocumentFetcherService")
    FolderDocumentFetcherService.stubs(:new).with("mock_access_token", "folder_123").returns(document_fetcher)
    document_fetcher.stubs(:fetch).raises(StandardError.new("Failed to fetch documents from Drive"))

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: 123)
    result = command.execute

    # Verify
    assert_nil result
    assert_includes command.errors, "Failed to fetch documents from Drive"
  end

  test "returns nil when grading task is not found" do
    # Setup
    GradingTask.stubs(:find_by).with(id: 999).returns(nil)

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: 999)
    result = command.execute

    # Verify
    assert_nil result
    assert_includes command.errors, "Grading task not found with ID: 999"
  end
end
