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
  end

  test "enqueues formatting jobs and creates submissions" do
    # Setup
    # Mock access token service
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    # Expect formatting jobs to be enqueued
    assert_enqueued_with(job: FormatAssignmentPromptJob, args: [ @grading_task.id ]) do
      assert_enqueued_with(job: FormatGradingRubricJob, args: [ @grading_task.id ]) do
        # Mock document fetcher
        document_fetcher = mock("FolderDocumentFetcherService")
        FolderDocumentFetcherService.stubs(:new).with("mock_access_token", @grading_task.folder_id).returns(document_fetcher)
        document_fetcher.stubs(:fetch).returns(@mock_documents)

        # Mock submission creator
        submission_creator = mock("SubmissionCreatorService")
        SubmissionCreatorService.stubs(:new).with(@grading_task, @mock_documents).returns(submission_creator)
        submission_creator.stubs(:create_submissions).returns(2)

        # Exercise
        command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id)
        result = command.execute

        # Verify
        assert_equal @grading_task, result
        assert_empty command.errors
      end
    end
  end

  test "handles empty folders" do
    # Setup
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    # Expect formatting jobs to be enqueued
    assert_enqueued_with(job: FormatAssignmentPromptJob, args: [ @grading_task.id ]) do
      assert_enqueued_with(job: FormatGradingRubricJob, args: [ @grading_task.id ]) do
        # Mock document fetcher to return empty array
        document_fetcher = mock("FolderDocumentFetcherService")
        FolderDocumentFetcherService.stubs(:new).with("mock_access_token", @grading_task.folder_id).returns(document_fetcher)
        document_fetcher.stubs(:fetch).returns([])

        # Mock submission creator to return 0 submissions
        submission_creator = mock("SubmissionCreatorService")
        SubmissionCreatorService.stubs(:new).with(@grading_task, []).returns(submission_creator)
        submission_creator.stubs(:create_submissions).returns(0)

        # Exercise
        command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id)
        result = command.execute

        # Verify
        assert_equal @grading_task, result
        assert_includes command.errors, "No submissions created from documents"
      end
    end
  end

  test "handles Google Drive service errors" do
    # Setup
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    # Expect formatting jobs to be enqueued
    assert_enqueued_with(job: FormatAssignmentPromptJob, args: [ @grading_task.id ]) do
      assert_enqueued_with(job: FormatGradingRubricJob, args: [ @grading_task.id ]) do
        # Mock document fetcher to raise an error
        document_fetcher = mock("FolderDocumentFetcherService")
        FolderDocumentFetcherService.stubs(:new).with("mock_access_token", @grading_task.folder_id).returns(document_fetcher)
        document_fetcher.stubs(:fetch).raises(StandardError.new("Failed to fetch documents from Drive"))

        # Exercise
        command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id)
        result = command.execute

        # Verify
        assert_nil result
        assert_includes command.errors, "Failed to fetch documents from Drive"
      end
    end
  end

  test "returns nil when grading task is not found" do
    GradingTask.delete_all

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: 12345)
    result = command.execute

    # Verify
    assert_nil result
    assert_includes command.errors, "Grading task not found with ID: 12345"
  end
end
