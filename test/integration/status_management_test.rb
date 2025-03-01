# frozen_string_literal: true

require "test_helper"

class StatusManagementTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:teacher)
    @grading_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Write an essay about Ruby on Rails",
      grading_rubric: "Evaluate based on clarity, accuracy, and completeness",
      folder_id: "test_folder_id",
      folder_name: "Test Folder",
      status: :pending
    )
  end

  test "end-to-end grading task flow with the new StatusManager" do
    # Step 1: Create student submissions
    doc_ids = [ "doc1", "doc2", "doc3" ]
    submissions = []

    doc_ids.each do |doc_id|
      ActiveRecord::Base.transaction do
        submission = StudentSubmission.create!(
          grading_task: @grading_task,
          original_doc_id: doc_id,
          status: :pending
        )
        submissions << submission

        # Update grading task status
        StatusManager.update_grading_task_status(@grading_task)
      end
    end

    # Refresh grading task from database
    @grading_task.reload

    # Verify initial state
    assert_equal 3, @grading_task.student_submissions.count
    assert_equal "pending", @grading_task.status
    assert_equal 0, StatusManager.calculate_progress_percentage(@grading_task)

    # Step 2: Transition a submission to processing
    StatusManager.transition_submission(submissions[0], :processing)
    @grading_task.reload

    # Verify processing state
    assert_equal "processing", @grading_task.status
    assert_equal "processing", submissions[0].reload.status
    assert_equal 0, StatusManager.calculate_progress_percentage(@grading_task)

    # Step 3: Complete the first submission
    StatusManager.transition_submission(
      submissions[0],
      :completed,
      { feedback: "Great job!", graded_doc_id: "graded_#{submissions[0].original_doc_id}" }
    )

    # Still processing overall because other submissions are pending
    @grading_task.reload
    assert_equal "pending", @grading_task.status
    assert_equal 33, StatusManager.calculate_progress_percentage(@grading_task)

    # Step 4: Transition the second submission to processing then failure
    StatusManager.transition_submission(submissions[1], :processing)
    @grading_task.reload
    assert_equal "processing", @grading_task.status

    StatusManager.transition_submission(
      submissions[1],
      :failed,
      { feedback: "Error processing submission" }
    )

    # Step 5: Complete the last submission
    StatusManager.transition_submission(submissions[2], :processing)
    StatusManager.transition_submission(
      submissions[2],
      :completed,
      { feedback: "Good work", graded_doc_id: "graded_#{submissions[2].original_doc_id}" }
    )

    # Verify final state - should be completed_with_errors because one submission failed
    @grading_task.reload
    assert_equal "completed_with_errors", @grading_task.status
    assert_equal 100, StatusManager.calculate_progress_percentage(@grading_task)

    # Step 6: Retry the failed submission
    failed_submission = submissions[1].reload
    assert_equal "failed", failed_submission.status

    # Retry using StatusManager
    StatusManager.retry_submission(failed_submission)
    failed_submission.reload
    @grading_task.reload

    # Verify retry worked
    assert_equal "pending", failed_submission.status
    assert_equal "pending", @grading_task.status
    # 2 out of 3 submissions are complete (66%)
    assert_equal 66, StatusManager.calculate_progress_percentage(@grading_task)

    # Step 7: Complete the retried submission
    StatusManager.transition_submission(failed_submission, :processing)
    StatusManager.transition_submission(
      failed_submission,
      :completed,
      { feedback: "Better after retry", graded_doc_id: "graded_#{failed_submission.original_doc_id}" }
    )

    # Verify all completed state
    @grading_task.reload
    assert_equal "completed", @grading_task.status
    assert_equal 100, StatusManager.calculate_progress_percentage(@grading_task)
    assert_equal 3, @grading_task.student_submissions.completed.count
  end
end
