# frozen_string_literal: true

require "test_helper"

class StudentSubmissionTest < ActiveSupport::TestCase
  setup do
    @grading_task = grading_tasks(:one)
    @submission = StudentSubmission.new(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_123",
      status: :pending
    )
  end

  test "belongs to a grading task" do
    assert_respond_to @submission, :grading_task
    @submission.grading_task = nil
    assert_not @submission.valid?
    assert_includes @submission.errors[:grading_task], "must exist"
  end

  test "requires original_doc_id" do
    @submission.original_doc_id = nil
    assert_not @submission.valid?
    assert_includes @submission.errors[:original_doc_id], "can't be blank"

    @submission.original_doc_id = ""
    assert_not @submission.valid?
    assert_includes @submission.errors[:original_doc_id], "can't be blank"

    @submission.original_doc_id = "google_doc_id_123"
    assert @submission.valid?
  end

  test "has a status enum with required states" do
    # Check that the model defines the enum
    assert_respond_to StudentSubmission, :statuses

    # Verify all required statuses are defined
    required_statuses = %w[pending processing completed failed]
    required_statuses.each do |status|
      assert_includes StudentSubmission.statuses.keys, status, "Status '#{status}' should be defined"
    end

    # Test each status individually - creating directly with the status
    # New records bypass the transition validation, so we should be able to create with any status
    pending_submission = StudentSubmission.new(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_123",
      status: :pending
    )
    assert pending_submission.valid?, "Should be valid with status 'pending'"

    processing_submission = StudentSubmission.new(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_456",
      status: :processing
    )
    assert processing_submission.valid?, "Should be valid with status 'processing'"

    completed_submission = StudentSubmission.new(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_789",
      status: :completed
    )
    assert completed_submission.valid?, "Should be valid with status 'completed'"

    failed_submission = StudentSubmission.new(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_012",
      status: :failed
    )
    assert failed_submission.valid?, "Should be valid with status 'failed'"
  end

  test "restricts status transitions" do
    # Create and save a pending submission
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_123",
      status: :pending
    )

    # Allowed transitions
    assert submission.update(status: :processing), "Should allow pending → processing"
    assert submission.update(status: :failed), "Should allow processing → failed"

    # Reset to processing
    submission.update_column(:status, :processing)
    assert submission.update(status: :completed), "Should allow processing → completed"

    # Reset to completed
    submission.update_column(:status, :completed)
    assert_not submission.update(status: :pending), "Should not allow completed → pending"
    assert_includes submission.errors[:status], "can't transition from 'completed' to 'pending'"

    # Failed submissions can't transition to completed
    submission.update_column(:status, :failed)
    assert_not submission.update(status: :completed), "Should not allow failed → completed"
    assert_includes submission.errors[:status], "can't transition from 'failed' to 'completed'"
  end

  test "has methods for checking each status" do
    submission = StudentSubmission.new(status: :pending)
    assert submission.pending?
    assert_not submission.processing?
    assert_not submission.completed?
    assert_not submission.failed?

    submission.status = :processing
    assert submission.processing?
    assert_not submission.pending?

    submission.status = :completed
    assert submission.completed?

    submission.status = :failed
    assert submission.failed?
  end

  test "can_transition_to? checks valid transitions" do
    # New record can transition to any state
    new_submission = StudentSubmission.new
    assert new_submission.can_transition_to?(:pending)
    assert new_submission.can_transition_to?(:processing)
    assert new_submission.can_transition_to?(:completed)
    assert new_submission.can_transition_to?(:failed)

    # Saved record follows transition rules
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_123",
      status: :pending
    )

    # From pending
    assert submission.can_transition_to?(:processing)
    assert submission.can_transition_to?(:failed)
    assert_not submission.can_transition_to?(:completed)
    assert_not submission.can_transition_to?(:pending)

    # From processing
    submission.update_column(:status, :processing)
    assert submission.can_transition_to?(:completed)
    assert submission.can_transition_to?(:failed)
    assert_not submission.can_transition_to?(:pending)
    assert_not submission.can_transition_to?(:processing)

    # From completed
    submission.update_column(:status, :completed)
    assert_not submission.can_transition_to?(:pending)
    assert_not submission.can_transition_to?(:processing)
    assert_not submission.can_transition_to?(:failed)
    assert_not submission.can_transition_to?(:completed)

    # From failed
    submission.update_column(:status, :failed)
    assert_not submission.can_transition_to?(:pending)
    assert_not submission.can_transition_to?(:processing)
    assert_not submission.can_transition_to?(:completed)
    assert_not submission.can_transition_to?(:failed)
  end

  test "retry! resets failed submissions to pending" do
    # Create a failed submission
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_123",
      status: :failed
    )

    # Test retry
    assert submission.retry!
    assert submission.pending?

    # Retry only works on failed submissions
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_456",
      status: :completed
    )

    assert_not submission.retry!
    assert submission.completed?
  end
end
