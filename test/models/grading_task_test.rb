require "test_helper"

class GradingTaskTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)

    # Create a grading task - removed counter fields
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
  end

  test "calculates_progress_percentage" do
    # Create 5 submissions
    submissions = []
    5.times do |i|
      submission = StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "doc_#{i}",
        status: :pending
      )
      submissions << submission
    end

    # Update the grading task status
    StatusManager.update_grading_task_status(@grading_task)
    @grading_task.reload

    # At the start, all submissions are pending (0% complete)
    assert_equal 0, @grading_task.progress_percentage

    # Complete 2 submissions (2/5 = 40%)
    StatusManager.transition_submission(submissions[0], :processing)
    StatusManager.transition_submission(submissions[0], :completed)

    StatusManager.transition_submission(submissions[1], :processing)
    StatusManager.transition_submission(submissions[1], :completed)

    @grading_task.reload
    assert_equal 40, @grading_task.progress_percentage

    # Update 1 submission to failed (failed counts toward completion for progress %)
    StatusManager.transition_submission(submissions[2], :processing)
    StatusManager.transition_submission(submissions[2], :failed)
    @grading_task.reload

    assert_equal 60, @grading_task.progress_percentage

    # Complete all submissions (100%)
    StatusManager.transition_submission(submissions[3], :processing)
    StatusManager.transition_submission(submissions[3], :completed)

    StatusManager.transition_submission(submissions[4], :processing)
    StatusManager.transition_submission(submissions[4], :completed)
    @grading_task.reload

    assert_equal 100, @grading_task.progress_percentage
  end

  test "has_correct_status_based_on_submission_states" do
    @grading_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Test assignment",
      grading_rubric: "Test rubric",
      folder_id: "folder_123",
      folder_name: "Test Folder",
      status: "pending"
    )

    submissions = []
    4.times do |i|
      submission = StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "doc_#{i}",
        status: :pending
      )
      submissions << submission
    end

    # Update the grading task status
    StatusManager.update_grading_task_status(@grading_task)
    @grading_task.reload

    assert_equal "pending", @grading_task.status

    # First submission goes to processing
    StatusManager.transition_submission(submissions[0], :processing)
    @grading_task.reload

    assert_equal "processing", @grading_task.status

    # Another submission also goes to processing
    StatusManager.transition_submission(submissions[1], :processing)
    @grading_task.reload
    assert_equal "processing", @grading_task.status

    # First submission completes
    StatusManager.transition_submission(submissions[0], :completed)
    @grading_task.reload
    assert_equal "processing", @grading_task.status

    # Second submission completes
    StatusManager.transition_submission(submissions[1], :completed)
    @grading_task.reload
    assert_equal "pending", @grading_task.status

    # Third submission goes to processing then completes
    StatusManager.transition_submission(submissions[2], :processing)
    @grading_task.reload
    assert_equal "processing", @grading_task.status

    StatusManager.transition_submission(submissions[2], :completed)
    @grading_task.reload
    assert_equal "pending", @grading_task.status

    # Last submission goes to processing then completes
    StatusManager.transition_submission(submissions[3], :processing)
    @grading_task.reload
    assert_equal "processing", @grading_task.status

    StatusManager.transition_submission(submissions[3], :completed)
    @grading_task.reload
    assert_equal "completed", @grading_task.status

    # Create another set with failures
    @grading_task2 = GradingTask.create!(
      user: @user,
      assignment_prompt: "Another assignment",
      grading_rubric: "Basic rubric",
      folder_id: "folder_456",
      folder_name: "Another Folder",
      status: "pending"
    )

    more_submissions = []
    3.times do |i|
      submission = StudentSubmission.create!(
        grading_task: @grading_task2,
        original_doc_id: "more_doc_#{i}",
        status: :pending
      )
      more_submissions << submission
    end

    # Update the grading task status
    StatusManager.update_grading_task_status(@grading_task2)
    @grading_task2.reload

    # Complete with errors when at least one submission failed
    StatusManager.transition_submission(more_submissions[0], :processing)
    StatusManager.transition_submission(more_submissions[0], :completed)

    StatusManager.transition_submission(more_submissions[1], :processing)
    StatusManager.transition_submission(more_submissions[1], :completed)

    StatusManager.transition_submission(more_submissions[2], :processing)
    StatusManager.transition_submission(more_submissions[2], :failed)

    @grading_task2.reload
    assert_equal "completed_with_errors", @grading_task2.status
  end
end
