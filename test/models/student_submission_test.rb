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

  test "can_transition_to? delegates to StatusManager" do
    # Create a submission
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_123",
      status: :pending
    )

    # From pending
    assert submission.can_transition_to?(:processing)
    assert submission.can_transition_to?(:failed)
    assert_not submission.can_transition_to?(:completed)

    # From processing
    submission.update!(status: :processing)
    assert submission.can_transition_to?(:completed)
    assert submission.can_transition_to?(:failed)
    assert_not submission.can_transition_to?(:pending)

    # From completed
    submission.update!(status: :completed)
    assert_not submission.can_transition_to?(:pending)
    assert_not submission.can_transition_to?(:processing)
    assert_not submission.can_transition_to?(:failed)

    # From failed - special case for retry
    submission.update!(status: :failed)
    # Special case: failed submissions can be retried (transitioned to pending)
    assert submission.can_transition_to?(:pending)
    assert_not submission.can_transition_to?(:processing)
    assert_not submission.can_transition_to?(:completed)
  end

  test "retry! delegates to StatusManager" do
    # Create a submission and transition it to failed
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_123",
      status: :pending
    )

    # Transition to failed using StatusManager
    StatusManager.transition_submission(submission, :processing)
    StatusManager.transition_submission(submission, :failed)

    # Test retry
    assert submission.retry!
    assert_equal "pending", submission.reload.status

    # Retry only works on failed submissions
    submission = StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: "google_doc_id_456",
      status: :pending
    )

    # Transition to completed using StatusManager
    StatusManager.transition_submission(submission, :processing)
    StatusManager.transition_submission(submission, :completed)

    assert_not submission.retry!
    assert_equal "completed", submission.reload.status
  end

  # Tests for structured grading data
  test "returns document title from metadata" do
    submission = student_submissions(:completed_submission)
    assert_equal "Essay on Climate Change", submission.document_title

    # Test fallback when no title is present
    submission = student_submissions(:pending_submission)
    assert_equal "Document doc123", submission.document_title
  end

  test "display_strengths parses newline-delimited lists" do
    submission = student_submissions(:completed_submission)
    strengths = submission.display_strengths

    assert_kind_of Array, strengths
    assert_equal 3, strengths.size
    assert_includes strengths, "Clear thesis statement"
    assert_includes strengths, "Good organization of ideas"
    assert_includes strengths, "Effective use of transitions"
  end

  test "display_strengths parses JSON array format" do
    submission = student_submissions(:json_array_submission)
    strengths = submission.display_strengths

    assert_kind_of Array, strengths
    assert_equal 3, strengths.size
    assert_includes strengths, "Clear introduction"
    assert_includes strengths, "Good grammar"
    assert_includes strengths, "Logical structure"
  end

  test "display_strengths handles simple string format" do
    submission = student_submissions(:simple_string_submission)
    strengths = submission.display_strengths

    assert_kind_of Array, strengths
    assert_equal 1, strengths.size
    assert_equal "Good overall work", strengths.first
  end

  test "display_strengths handles missing data" do
    submission = student_submissions(:pending_submission)
    strengths = submission.display_strengths

    assert_kind_of Array, strengths
    assert_empty strengths
  end

  test "display_opportunities parses newline-delimited lists" do
    submission = student_submissions(:completed_submission)
    opportunities = submission.display_opportunities

    assert_kind_of Array, opportunities
    assert_equal 3, opportunities.size
    assert_includes opportunities, "Add more supporting evidence"
    assert_includes opportunities, "Expand the conclusion"
    assert_includes opportunities, "Consider counterarguments"
  end

  test "display_opportunities parses JSON array format" do
    submission = student_submissions(:json_array_submission)
    opportunities = submission.display_opportunities

    assert_kind_of Array, opportunities
    assert_equal 2, opportunities.size
    assert_includes opportunities, "Needs more examples"
    assert_includes opportunities, "Conclusion is weak"
  end

  test "display_opportunities handles simple string format" do
    submission = student_submissions(:simple_string_submission)
    opportunities = submission.display_opportunities

    assert_kind_of Array, opportunities
    assert_equal 1, opportunities.size
    assert_equal "Need more detail", opportunities.first
  end

  test "display_opportunities handles missing data" do
    submission = student_submissions(:pending_submission)
    opportunities = submission.display_opportunities

    assert_kind_of Array, opportunities
    assert_empty opportunities
  end

  test "display_rubric_scores parses YAML hash format" do
    submission = student_submissions(:completed_submission)
    scores = submission.display_rubric_scores

    assert_kind_of Hash, scores
    assert_equal 3, scores.size
    assert_equal 38, scores[:content] || scores["content"]
    assert_equal 28, scores[:structure] || scores["structure"]
    assert_equal 27, scores[:grammar] || scores["grammar"]
  end

  test "display_rubric_scores parses JSON hash format" do
    submission = student_submissions(:json_array_submission)
    scores = submission.display_rubric_scores

    assert_kind_of Hash, scores
    assert_equal 3, scores.size
    assert_equal 35, scores["content"]
    assert_equal 25, scores["structure"]
    assert_equal 29, scores["grammar"]
  end

  test "display_rubric_scores handles missing data" do
    submission = student_submissions(:simple_string_submission)
    scores = submission.display_rubric_scores

    assert_kind_of Hash, scores
    assert_empty scores
  end
end
