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

  test "fetches documents from Google Drive and creates submissions" do
    # Setup
    # Mock access token service
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    assignment_prompt_formatter_service = mock("AssignmentPromptFormatterService")
    AssignmentPromptFormatterService.stubs(:new).returns(assignment_prompt_formatter_service)
    assignment_prompt_formatter_service.stubs(:format).returns(@grading_task)

    grading_rubric_formatter_service = mock("GradingRubricFormatterService")
    GradingRubricFormatterService.stubs(:new).returns(grading_rubric_formatter_service)
    grading_rubric_formatter_service.stubs(:format).returns(@grading_task)

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

  test "handles empty folders" do
    # Setup
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    assignment_prompt_formatter_service = mock("AssignmentPromptFormatterService")
    AssignmentPromptFormatterService.stubs(:new).returns(assignment_prompt_formatter_service)
    assignment_prompt_formatter_service.stubs(:format).returns(@grading_task)

    grading_rubric_formatter_service = mock("GradingRubricFormatterService")
    GradingRubricFormatterService.stubs(:new).returns(grading_rubric_formatter_service)
    grading_rubric_formatter_service.stubs(:format).returns(@grading_task)

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

  test "handles Google Drive service errors" do
    # Setup
    token_service = mock("GradingTaskAccessTokenService")
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    assignment_prompt_formatter_service = mock("AssignmentPromptFormatterService")
    AssignmentPromptFormatterService.stubs(:new).returns(assignment_prompt_formatter_service)
    assignment_prompt_formatter_service.stubs(:format).returns(@grading_task)

    grading_rubric_formatter_service = mock("GradingRubricFormatterService")
    GradingRubricFormatterService.stubs(:new).returns(grading_rubric_formatter_service)
    grading_rubric_formatter_service.stubs(:format).returns(@grading_task)

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

  test "returns nil when grading task is not found" do
    GradingTask.delete_all

    # Exercise
    command = ProcessGradingTaskCommand.new(grading_task_id: 12345)
    result = command.execute

    # Verify
    assert_nil result
    assert_includes command.errors, "Grading task not found with ID: 12345"
  end

  test "formats assignment prompt and rubric before processing submissions" do
    formatted_prompt = "<div><h1>Assignment</h1><p>Write an essay</p></div>"
    formatted_rubric = "<div><h1>Rubric</h1><ul><li>Grammar: 20%</li></ul></div>"

    # Mock the formatting services
    prompt_formatter = mock
    AssignmentPromptFormatterService.stubs(:new).returns(prompt_formatter)
    prompt_formatter.expects(:format).with(@grading_task).returns(@grading_task)

    rubric_formatter = mock
    GradingRubricFormatterService.stubs(:new).returns(rubric_formatter)
    rubric_formatter.expects(:format).with(@grading_task).returns(@grading_task)

    # Mock the rest of the services
    token_service = mock
    GradingTaskAccessTokenService.stubs(:new).with(@grading_task).returns(token_service)
    token_service.stubs(:fetch_token).returns("mock_access_token")

    document_fetcher = mock
    FolderDocumentFetcherService.stubs(:new).with("mock_access_token", @grading_task.folder_id).returns(document_fetcher)
    document_fetcher.stubs(:fetch).returns(@mock_documents)

    submission_creator = mock
    SubmissionCreatorService.stubs(:new).with(@grading_task, @mock_documents).returns(submission_creator)
    submission_creator.stubs(:create_submissions).returns(2)

    # Execute the command
    command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id)
    result = command.execute

    assert_equal @grading_task, result
    assert_empty command.errors
  end

  test "handles formatting service errors gracefully" do
    # Mock the formatting service to raise an error
    prompt_formatter = mock
    AssignmentPromptFormatterService.stubs(:new).returns(prompt_formatter)
    prompt_formatter.expects(:format).raises(StandardError.new("LLM service unavailable"))

    # Execute the command
    command = ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id)
    result = command.execute

    assert_nil result
    assert_includes command.errors, "LLM service unavailable"
  end
end
