require "test_helper"

class GradingTaskTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @user = users(:teacher)

    # Create a grading task - removed counter fields
    @grading_task = GradingTask.create!(
      user: @user,
      assignment_prompt: "Write an essay on climate change",
      grading_rubric: "Content: 40%, Structure: 30%, Grammar: 30%",
      status: "created"
    )

    # Clear existing submissions
    StudentSubmission.where(grading_task: @grading_task).delete_all
  end

  test "display_name returns truncated assignment prompt when longer than 120 characters" do
    # Setup
    short_prompt = "This is a short assignment prompt"
    long_prompt = "This is a very long assignment prompt that exceeds the 120 character limit. It contains a lot of detailed information about what students should do for this particular assignment and how they should approach it. This text should definitely be truncated."

    # Create test grading tasks
    short_task = GradingTask.new(user: @user, assignment_prompt: short_prompt, grading_rubric: "Test rubric")
    long_task = GradingTask.new(user: @user, assignment_prompt: long_prompt, grading_rubric: "Test rubric")

    # Exercise & Verify
    assert_equal short_prompt, short_task.display_name
    assert_equal long_prompt.truncate(60), long_task.display_name
    assert_equal 60, long_task.display_name.length
    assert long_task.display_name.end_with?("..."), "Expected truncated text to end with '...'"
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
      status: "rubric_processed"  # Set to a state that allows submissions processing
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

    assert_equal "submissions_processing", @grading_task.status

    # First submission goes to processing
    StatusManager.transition_submission(submissions[0], :processing)
    @grading_task.reload

    assert_equal "submissions_processing", @grading_task.status

    # Another submission also goes to processing
    StatusManager.transition_submission(submissions[1], :processing)
    @grading_task.reload
    assert_equal "submissions_processing", @grading_task.status

    # First submission completes
    StatusManager.transition_submission(submissions[0], :completed)
    @grading_task.reload
    assert_equal "submissions_processing", @grading_task.status

    # Second submission completes
    StatusManager.transition_submission(submissions[1], :completed)
    @grading_task.reload
    assert_equal "submissions_processing", @grading_task.status

    # Third submission goes to processing then completes
    StatusManager.transition_submission(submissions[2], :processing)
    @grading_task.reload
    assert_equal "submissions_processing", @grading_task.status

    StatusManager.transition_submission(submissions[2], :completed)
    @grading_task.reload
    assert_equal "submissions_processing", @grading_task.status

    # Last submission goes to processing then completes
    StatusManager.transition_submission(submissions[3], :processing)
    @grading_task.reload
    assert_equal "submissions_processing", @grading_task.status

    StatusManager.transition_submission(submissions[3], :completed)
    @grading_task.reload
    assert_equal "completed", @grading_task.status

    # Create another set with failures
    @grading_task2 = GradingTask.create!(
      user: @user,
      assignment_prompt: "Another assignment",
      grading_rubric: "Basic rubric",
      status: "created"
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
    @grading_task2.update!(status: :submissions_processing)

    StatusManager.transition_submission(more_submissions[0], :processing)
    StatusManager.transition_submission(more_submissions[0], :completed)

    StatusManager.transition_submission(more_submissions[1], :processing)
    StatusManager.transition_submission(more_submissions[1], :completed)

    StatusManager.transition_submission(more_submissions[2], :processing)
    StatusManager.transition_submission(more_submissions[2], :failed)

    @grading_task2.reload
    assert_equal "completed_with_errors", @grading_task2.status
  end

  test "follows correct workflow sequence" do
    grading_task = grading_tasks(:one)
    grading_task.update!(status: :created)

    assert_equal "created", grading_task.status

    # Test transitions
    assert grading_task.may_start_assignment_processing?
    assert grading_task.start_assignment_processing!
    assert_equal "assignment_processing", grading_task.status

    assert grading_task.may_complete_assignment_processing?
    assert grading_task.complete_assignment_processing!
    assert_equal "rubric_processing", grading_task.status

    assert grading_task.may_complete_rubric_processing?
    assert grading_task.complete_rubric_processing!
    assert_equal "submissions_processing", grading_task.status

    assert grading_task.may_complete_processing?
    assert grading_task.complete_processing!
    assert_equal "completed", grading_task.status
  end

  test "prevents invalid transitions" do
    grading_task = grading_tasks(:one)
    grading_task.update!(status: :created)

    # Try to skip a step
    assert_not grading_task.may_complete_assignment_processing?
    assert_not grading_task.complete_assignment_processing!
    assert_equal "created", grading_task.status

    # Try to go backwards
    grading_task.update_column(:status, "assignment_processed")
    assert_not grading_task.may_start_assignment_processing?
    assert_not grading_task.start_assignment_processing!
    assert_equal "assignment_processed", grading_task.status
  end

  test "can_transition_to_failed_from_any_state" do
    # Test each state individually to avoid validation issues

    # Test from created state
    grading_task = grading_tasks(:one)
    grading_task.update!(status: :created)
    assert grading_task.fail!
    assert_equal "failed", grading_task.status

    # Test from assignment_processing state
    grading_task = grading_tasks(:one)
    grading_task.update_column(:status, :assignment_processing)
    assert grading_task.fail!
    assert_equal "failed", grading_task.status

    # Test from assignment_processed state
    grading_task = grading_tasks(:one)
    grading_task.update_column(:status, :assignment_processed)
    assert grading_task.fail!
    assert_equal "failed", grading_task.status

    # Test from rubric_processing state
    grading_task = grading_tasks(:one)
    grading_task.update_column(:status, :rubric_processing)
    assert grading_task.fail!
    assert_equal "failed", grading_task.status

    # Test from rubric_processed state
    grading_task = grading_tasks(:one)
    grading_task.update_column(:status, :rubric_processed)
    assert grading_task.fail!
    assert_equal "failed", grading_task.status

    # Test from submissions_processing state
    grading_task = grading_tasks(:one)
    grading_task.update_column(:status, :submissions_processing)
    assert grading_task.fail!
    assert_equal "failed", grading_task.status

    # Test from completed state
    grading_task = grading_tasks(:one)
    grading_task.update_column(:status, :completed)
    assert grading_task.fail!
    assert_equal "failed", grading_task.status
  end

  test "provides correct status label" do
    grading_task = grading_tasks(:one)

    grading_task.update!(status: :created)
    assert_equal "Created", grading_task.status_label

    grading_task.update!(status: :assignment_processing)
    assert_equal "Processing Assignment...", grading_task.status_label

    grading_task.update!(status: :completed)
    assert_equal "Completed", grading_task.status_label
  end

  test "broadcasts_status_updates_on_state_changes" do
    # Test that status updates are broadcast when state changes
    assert_broadcasts("grading_task_#{@grading_task.id}", 1) do
      @grading_task.start_assignment_processing!
    end

    # Reset the grading task for the next test
    @grading_task.update_column(:status, "created")

    # Test that status updates are broadcast when transitioning through multiple states
    assert_broadcasts("grading_task_#{@grading_task.id}", 4) do
      @grading_task.start_assignment_processing!
      @grading_task.complete_assignment_processing!
    end
  end

  test "status_label_returns_correct_label" do
    # Test each status and its corresponding label
    statuses_and_labels = {
      created: "Created",
      assignment_processing: "Processing Assignment...",
      assignment_processed: "Assignment Processed",
      rubric_processing: "Processing Rubric...",
      rubric_processed: "Rubric Processed",
      submissions_processing: "Processing Submissions...",
      completed: "Completed",
      completed_with_errors: "Completed with Errors",
      failed: "Failed"
    }

    statuses_and_labels.each do |status, label|
      @grading_task.update_column(:status, status)
      @grading_task.reload
      assert_equal label, @grading_task.status_label, "Expected status '#{status}' to have label '#{label}'"
    end
  end
end
