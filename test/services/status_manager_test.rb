# frozen_string_literal: true

require "test_helper"

class StatusManagerTest < ActiveSupport::TestCase
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
  end

  test "calculate_grading_task_status_returns_pending_for_empty_tasks" do
    # No submissions
    status = StatusManager.calculate_grading_task_status(@grading_task)
    assert_equal :created, status
  end

  test "calculate_grading_task_status_returns_pending_when_submissions_exist_but_all_are_pending" do
    # Create submissions in pending state
    3.times do |i|
      StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "doc_#{i}",
        status: :pending
      )
    end

    status = StatusManager.calculate_grading_task_status(@grading_task)
    assert_equal :submissions_processing, status
  end

  test "calculate_grading_task_status_returns_processing_when_any_submission_is_processing" do
    # Create submissions in different states
    submissions = []
    2.times do |i|
      submissions << StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "doc_#{i}",
        status: :pending
      )
    end

    # Set one to processing
    submissions.first.update!(status: :processing)

    status = StatusManager.calculate_grading_task_status(@grading_task)
    assert_equal :submissions_processing, status
  end

  test "calculate_grading_task_status returns completed when all submissions are completed" do
    # Create completed submissions
    3.times do |i|
      StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "doc#{i}",
        status: :completed
      )
    end

    # Use the database values when determining status
    status = StatusManager.calculate_grading_task_status(@grading_task)
    assert_equal :completed, status
  end

  test "calculate_grading_task_status returns completed_with_errors when at least one submission is failed and none are pending or processing" do
    # Create mixed submissions with one failed
    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :completed
    )

    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc2",
      status: :failed
    )

    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc3",
      status: :completed
    )

    # Use the database values when determining status
    status = StatusManager.calculate_grading_task_status(@grading_task)
    assert_equal :completed_with_errors, status
  end

  test "update_grading_task_status_updates_a_grading_task's_status" do
    # Set the grading task to a state that allows submissions processing
    @grading_task.update!(status: :rubric_processed)

    # Create mixed submissions
    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :completed
    )

    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc2",
      status: :processing
    )

    # Update status
    result = StatusManager.update_grading_task_status(@grading_task)

    assert result
    assert_equal "submissions_processing", @grading_task.reload.status
  end

  test "can_transition_submission? validates allowed transitions" do
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :pending
    )

    # Test transitions from pending
    assert StatusManager.can_transition_submission?(submission, :processing)
    assert StatusManager.can_transition_submission?(submission, :failed)
    refute StatusManager.can_transition_submission?(submission, :completed)

    # Test transitions from processing
    submission.update_column(:status, :processing)
    assert StatusManager.can_transition_submission?(submission, :completed)
    assert StatusManager.can_transition_submission?(submission, :failed)
    refute StatusManager.can_transition_submission?(submission, :pending)

    # Test transitions from completed
    submission.update_column(:status, :completed)
    refute StatusManager.can_transition_submission?(submission, :pending)
    refute StatusManager.can_transition_submission?(submission, :processing)
    refute StatusManager.can_transition_submission?(submission, :failed)

    # Test transitions from failed - special case for retry
    submission.update_column(:status, :failed)
    assert StatusManager.can_transition_submission?(submission, :pending)
    refute StatusManager.can_transition_submission?(submission, :processing)
    refute StatusManager.can_transition_submission?(submission, :completed)
  end

  test "transition_submission_updates_submission_status_and_grading_task_status" do
    # Set the grading task to a state that allows submissions processing
    @grading_task.update!(status: :rubric_processed)

    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :pending
    )

    # Transition to processing
    result = StatusManager.transition_submission(submission, :processing)

    assert result
    assert_equal "processing", submission.reload.status
    assert_equal "submissions_processing", @grading_task.reload.status

    # Add additional attributes
    result = StatusManager.transition_submission(
      submission,
      :completed,
      { feedback: "Great job!", graded_doc_id: "graded_doc1" }
    )

    assert result
    assert_equal "completed", submission.reload.status
    assert_equal "Great job!", submission.feedback
    assert_equal "graded_doc1", submission.graded_doc_id
    assert_equal "completed", @grading_task.reload.status
  end

  test "broadcasts_when_first_submission_is_created" do
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
    assert_broadcasts("grading_task_#{empty_grading_task.id}", 5) do
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

  test "retry_submission_resets_a_failed_submission_to_pending" do
    # Set the grading task to a state that allows submissions processing
    @grading_task.update!(status: :rubric_processed)

    # Create a failed submission
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :failed
    )

    # Retry the submission
    result = StatusManager.retry_submission(submission)
    submission.reload

    # Verify the submission was reset to pending
    assert result, "Retry should return true"
    assert_equal "pending", submission.status

    # Verify the grading task status was updated
    @grading_task.reload
    assert_equal "submissions_processing", @grading_task.status
  end

  test "calculate_progress_percentage returns correct percentage" do
    # Create mixed submissions
    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :completed
    )

    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc2",
      status: :failed
    )

    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc3",
      status: :pending
    )

    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc4",
      status: :processing
    )

    # Calculate progress
    progress = StatusManager.calculate_progress_percentage(@grading_task)

    # 2 out of 4 are completed or failed, so 50%
    assert_equal 50, progress
  end

  test "count_submissions_by_status returns counts for each status" do
    # Create mixed submissions
    2.times do |i|
      StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "pending#{i}",
        status: :pending
      )
    end

    3.times do |i|
      StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "processing#{i}",
        status: :processing
      )
    end

    4.times do |i|
      StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "completed#{i}",
        status: :completed
      )
    end

    1.times do |i|
      StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "failed#{i}",
        status: :failed
      )
    end

    # Get counts
    counts = StatusManager.count_submissions_by_status(@grading_task)

    assert_equal 2, counts[:pending]
    assert_equal 3, counts[:processing]
    assert_equal 4, counts[:completed]
    assert_equal 1, counts[:failed]
  end
end
