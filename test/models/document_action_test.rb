require "test_helper"

class DocumentActionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @student_submission = student_submissions(:completed_submission)
    @valid_attributes = {
      action_type: :post_feedback,
      status: :pending,
      student_submission: @student_submission
    }
  end

  # ==== Validations ====

  test "should be valid with valid attributes" do
    document_action = DocumentAction.new(@valid_attributes)
    assert document_action.valid?
  end

  test "should require action_type" do
    document_action = DocumentAction.new(@valid_attributes.merge(action_type: nil))
    assert_not document_action.valid?
    assert_includes document_action.errors[:action_type], "can't be blank"
  end

  test "should require student_submission_id" do
    document_action = DocumentAction.new(@valid_attributes.merge(student_submission: nil))
    assert_not document_action.valid?
    assert_includes document_action.errors[:student_submission_id], "can't be blank"
  end

  # ==== State Transitions ====

  test "should validate forward-only status transitions" do
    document_action = DocumentAction.create!(@valid_attributes)

    # Valid transitions
    assert document_action.pending?
    assert document_action.start_processing!
    assert document_action.processing?
    assert document_action.complete!
    assert document_action.completed?

    # Attempt an invalid transition (backward)
    document_action.status = :processing
    assert_not document_action.valid?
    assert_includes document_action.errors[:status], "cannot transition from completed to processing"
  end

  test "should allow transition to failed from any state" do
    # From pending
    document_action = DocumentAction.create!(@valid_attributes)
    assert document_action.pending?
    assert document_action.fail!("Error from pending")
    assert document_action.failed?

    # From processing
    document_action = DocumentAction.create!(@valid_attributes)
    document_action.start_processing!
    assert document_action.processing?
    assert document_action.fail!("Error from processing")
    assert document_action.failed?

    # From completed
    document_action = DocumentAction.create!(@valid_attributes)
    document_action.start_processing!
    document_action.complete!
    assert document_action.completed?
    assert document_action.fail!("Error from completed")
    assert document_action.failed?
  end

  # ==== Callbacks ====

  test "should enqueue PostFeedbackJob after creation" do
    assert_enqueued_with(job: PostFeedbackJob) do
      document_action = DocumentAction.create!(@valid_attributes)
      assert_equal document_action.id, ActiveJob::Base.queue_adapter.enqueued_jobs.last[:args].first
    end
  end

  # ==== State Transition Methods ====

  test "should not start processing if not in pending state" do
    # Create and transition to processing
    document_action = DocumentAction.create!(@valid_attributes)
    document_action.start_processing!
    document_action.complete!

    # Attempt to start processing again from completed state
    assert_not document_action.start_processing!
  end

  test "should not complete if not in processing state" do
    # Create but don't transition to processing
    document_action = DocumentAction.create!(@valid_attributes)

    # Attempt to complete from pending state
    assert_not document_action.complete!
  end

  test "should set completed_at timestamp when completing" do
    document_action = DocumentAction.create!(@valid_attributes)
    document_action.start_processing!

    freeze_time do
      document_action.complete!
      assert_equal Time.current, document_action.completed_at
    end
  end

  test "should set failed_at timestamp and error_message when failing" do
    document_action = DocumentAction.create!(@valid_attributes)
    error_message = "Something went wrong"

    freeze_time do
      document_action.fail!(error_message)
      assert_equal Time.current, document_action.failed_at
      assert_equal error_message, document_action.error_message
    end
  end

  # ==== May Methods ====

  test "may_start_processing? returns true only in pending state" do
    document_action = DocumentAction.create!(@valid_attributes)
    assert document_action.may_start_processing?

    document_action.start_processing!
    assert_not document_action.may_start_processing?

    document_action.complete!
    assert_not document_action.may_start_processing?

    document_action = DocumentAction.create!(@valid_attributes)
    document_action.fail!
    assert_not document_action.may_start_processing?
  end

  test "may_complete? returns true only in processing state" do
    document_action = DocumentAction.create!(@valid_attributes)
    assert_not document_action.may_complete?

    document_action.start_processing!
    assert document_action.may_complete?

    document_action.complete!
    assert_not document_action.may_complete?

    document_action = DocumentAction.create!(@valid_attributes)
    document_action.fail!
    assert_not document_action.may_complete?
  end
end
