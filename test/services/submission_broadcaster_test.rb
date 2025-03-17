require "test_helper"

class SubmissionBroadcasterTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)
    @submission = student_submissions(:pending_submission)
  end

  test "broadcasts first submission correctly" do
    # Create a new grading task with no submissions
    empty_grading_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Write an essay about history",
      grading_rubric: "Content: 40%, Structure: 30%, Grammar: 30%",
      folder_id: "empty_folder_123",
      folder_name: "Empty Test Folder",
      status: "created"
    )

    # Create and save a new submission
    submission = StudentSubmission.create!(
      grading_task: empty_grading_task,
      original_doc_id: "first_doc",
      status: :pending
    )

    # Test that the broadcaster sends the correct broadcasts
    assert_broadcasts("grading_task_#{empty_grading_task.id}", 4) do
      # Create a broadcaster and broadcast the creation
      broadcaster = SubmissionBroadcaster.new(submission)
      broadcaster.broadcast_creation
    end
  end

  test "broadcasts subsequent submission correctly" do
    # Test that the broadcaster sends the correct broadcasts for a subsequent submission
    assert_broadcasts("grading_task_#{@grading_task.id}_submissions", 1) do
      # Create a new submission for an existing grading task
      submission = StudentSubmission.new(
        grading_task: @grading_task,
        original_doc_id: "subsequent_doc",
        status: :pending
      )

      # Create a broadcaster and broadcast the creation
      broadcaster = SubmissionBroadcaster.new(submission)
      broadcaster.broadcast_creation
    end
  end

  test "broadcasts submission update correctly" do
    # Test that the broadcaster sends the correct broadcasts for a submission update
    assert_broadcasts("grading_task_#{@grading_task.id}", 6) do
      # The broadcast should update the submission card and table row
      broadcaster = SubmissionBroadcaster.new(@submission)
      broadcaster.broadcast_update
    end

    # Test that it also broadcasts to the submission detail page
    assert_broadcasts("student_submission_#{@submission.id}", 2) do
      # The broadcast should update the detail view and header status
      broadcaster = SubmissionBroadcaster.new(@submission)
      broadcaster.broadcast_update
    end
  end
end
