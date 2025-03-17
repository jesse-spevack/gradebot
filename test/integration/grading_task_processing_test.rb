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

  test "creating student submissions broadcasts updates" do
    assert_broadcasts("grading_task_#{@grading_task.id}_submissions", 1) do
      CreateStudentSubmissionsCommand.new(grading_task: @grading_task).execute
    end

    # Verify submissions were created
    assert_equal 2, @grading_task.student_submissions.count

    # Verify the submissions have the correct attributes
    submissions = @grading_task.student_submissions.order(:original_doc_id)
    assert_equal "doc1", submissions.first.original_doc_id
    assert_equal "doc2", submissions.last.original_doc_id
    assert_equal "pending", submissions.first.status
    assert_equal "pending", submissions.last.status
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

  test "empty_state_is_replaced_when_first_submission_is_created" do
    # Create a new grading task with no submissions
    empty_grading_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Write an essay about history",
      grading_rubric: "Content: 40%, Structure: 30%, Grammar: 30%",
      folder_id: "empty_folder_123",
      folder_name: "Empty Test Folder",
      status: "created"
    )

    # This test will fail until we implement the empty state replacement
    assert_broadcasts("grading_task_#{empty_grading_task.id}", 4) do
      # Simulate the first submission being created
      # The actual broadcast will be implemented in the StudentSubmission model
      submission = StudentSubmission.new(
        grading_task: empty_grading_task,
        original_doc_id: "first_doc",
        status: :pending
      )

      # We'll need to manually trigger the broadcast in our implementation
      # This is just setting up the test expectation
      submission.save!
    end
  end
end
