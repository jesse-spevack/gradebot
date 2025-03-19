require "test_helper"

class GradingTaskProcessingTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @user = users(:teacher)
    @grading_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Write an essay on climate change",
      grading_rubric: "Content: 40%, Structure: 30%, Grammar: 30%",
      folder_id: "test_folder_123",
      folder_name: "Test Folder",
      status: "created"
    )

    # Clear existing submissions
    StudentSubmission.where(grading_task: @grading_task).delete_all

    # Mock the document fetcher to return test documents
    @documents = [
      { id: "doc1", name: "Student 1", mime_type: "application/vnd.google-apps.document" },
      { id: "doc2", name: "Student 2", mime_type: "application/vnd.google-apps.document" }
    ]

    FolderDocumentFetcherService.any_instance.stubs(:fetch).returns(@documents)
    GradingTaskAccessTokenService.any_instance.stubs(:fetch_token).returns("mock_token")
  end

  test "processing a grading task starts the workflow" do
    # First create submissions
    CreateStudentSubmissionsCommand.new(grading_task: @grading_task).execute

    # Then process the grading task
    ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id).execute

    # Verify the grading task status was updated
    @grading_task.reload
    assert_equal "assignment_processing", @grading_task.status
  end
end
