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
      status: "pending"
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

  test "processing a grading task creates and broadcasts submissions" do
    # This test will fail until we implement the broadcast on creation
    assert_broadcasts("grading_task_#{@grading_task.id}_submissions", 2) do
      # Process the grading task
      ProcessGradingTaskCommand.new(grading_task_id: @grading_task.id).execute
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

  test "empty state is replaced when first submission is created" do
    # This test will fail until we implement the empty state replacement
    assert_broadcasts("grading_task_#{@grading_task.id}", 1) do
      # Create just one submission to test the empty state replacement
      StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "first_doc",
        status: :pending
      )
    end

    # Verify the submission was created
    assert_equal 1, @grading_task.student_submissions.count
    assert_equal "first_doc", @grading_task.student_submissions.first.original_doc_id
  end
end
