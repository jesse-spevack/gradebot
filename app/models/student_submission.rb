# frozen_string_literal: true

# The StudentSubmission model represents a student's document that is being processed by the system
# for grading. It tracks the document through various states from submission to completion.
#
# == Status Flow
# A submission follows this standard flow:
#   pending -> processing -> completed
#
# If processing fails, it can go to the failed state:
#   pending -> processing -> failed
#   pending -> failed (for direct failures)
#
# Once a submission is in completed or failed state, it cannot transition to other states.
# Exception: Failed submissions can be retried using the retry! method which resets them to pending.
#
# == Attributes
#   * grading_task - The grading task this submission belongs to
#   * original_doc_id - Google Doc ID of the original submission document
#   * status - Current status of the submission (pending, processing, completed, failed)
#   * feedback - Textual feedback for the student
#   * graded_doc_id - Google Doc ID of the graded document (when completed)
class StudentSubmission < ApplicationRecord
  # Use optimistic locking
  # This model has a lock_version column for this purpose

  # Constants - kept for reference but actual transition logic moved to StatusManager
  ALLOWED_TRANSITIONS = {
    pending: [ :processing, :failed ],
    processing: [ :completed, :failed ],
    completed: [],
    failed: []
  }.freeze

  # Associations
  belongs_to :grading_task

  # Validations
  validates :original_doc_id, presence: true

  # Status transitions are now validated by StatusManager service
  # Status updates should go through StatusManager.transition_submission

  # Enums
  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :processing, -> { where(status: :processing) }
  scope :completed, -> { where(status: :completed) }
  scope :failed, -> { where(status: :failed) }
  scope :in_progress, -> { where(status: [ :pending, :processing ]) }
  scope :by_grading_task, ->(task_id) { where(grading_task_id: task_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :needs_processing, -> { pending.oldest_first }
  scope :created_after, ->(date) { where("created_at >= ?", date) }
  scope :created_before, ->(date) { where("created_at <= ?", date) }

  # Returns true if this submission can transition to the given status
  # Delegated to StatusManager
  #
  # @param new_status [Symbol, String] The status to check transition to
  # @return [Boolean] True if transition is allowed, false otherwise
  def can_transition_to?(new_status)
    StatusManager.can_transition_submission?(self, new_status)
  end

  # Retry a failed submission by resetting it to pending
  # Delegated to StatusManager
  #
  # @return [Boolean] True if the retry succeeded, false otherwise
  def retry!
    StatusManager.retry_submission(self)
  end
end
