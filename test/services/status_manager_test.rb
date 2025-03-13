# frozen_string_literal: true

require "test_helper"

class StatusManagerTest < ActiveSupport::TestCase
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
  end

  test "calculate_grading_task_status returns pending for empty tasks" do
    status = StatusManager.calculate_grading_task_status(@grading_task)
    assert_equal :pending, status
  end

  test "calculate_grading_task_status returns pending when submissions exist but all are pending" do
    # Create pending submissions
    3.times do |i|
      StudentSubmission.create!(
        grading_task: @grading_task,
        original_doc_id: "doc#{i}",
        status: :pending
      )
    end

    # Use the database values when determining status
    status = StatusManager.calculate_grading_task_status(@grading_task)
    assert_equal :pending, status
  end

  test "calculate_grading_task_status returns processing when any submission is processing" do
    # Create mixed submissions
    submissions = []

    # Create a pending submission
    submissions << StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :pending
    )

    # Create a processing submission
    submissions << StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc2",
      status: :processing
    )

    # Create a completed submission
    submissions << StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc3",
      status: :completed
    )

    # Use the database values when determining status
    status = StatusManager.calculate_grading_task_status(@grading_task)
    assert_equal :processing, status
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

  test "update_grading_task_status updates a grading task's status" do
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

    # Set incorrect status initially
    @grading_task.update!(status: :completed)

    # Update status
    result = StatusManager.update_grading_task_status(@grading_task)

    assert result
    assert_equal "processing", @grading_task.reload.status
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

  test "transition_submission updates submission status and grading task status" do
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :pending
    )

    @grading_task.update!(status: :pending)

    # Transition to processing
    result = StatusManager.transition_submission(submission, :processing)

    assert result
    assert_equal "processing", submission.reload.status
    assert_equal "processing", @grading_task.reload.status

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

  test "retry_submission resets a failed submission to pending" do
    # Create a failed submission
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "doc1",
      status: :failed
    )

    # Update the grading task status to reflect the failed submission
    StatusManager.update_grading_task_status(@grading_task)
    @grading_task.reload

    # Retry the submission
    result = StatusManager.retry_submission(submission)

    assert result
    assert_equal "pending", submission.reload.status
    assert_equal "pending", @grading_task.reload.status
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
