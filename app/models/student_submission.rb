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
#
# == Attributes
#   * grading_task - The grading task this submission belongs to
#   * original_doc_id - Google Doc ID of the original submission document
#   * status - Current status of the submission (pending, processing, completed, failed)
#   * feedback - Textual feedback for the student
#   * graded_doc_id - Google Doc ID of the graded document (when completed)
class StudentSubmission < ApplicationRecord
  # Constants
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
  validate :validate_status_transitions, if: :status_changed?

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
  #
  # @param new_status [Symbol, String] The status to check transition to
  # @return [Boolean] True if transition is allowed, false otherwise
  def can_transition_to?(new_status)
    new_status = new_status.to_sym if new_status.is_a?(String)
    return true if new_record?
    return false unless status.present?

    ALLOWED_TRANSITIONS[status.to_sym].include?(new_status)
  end

  # Retry a failed submission by resetting it to pending
  #
  # @return [Boolean] True if the retry succeeded, false otherwise
  def retry!
    return false unless failed?

    # Use update_column to bypass the transition validation
    update_column(:status, :pending)
  end

  private

  # Validates that status transitions follow the allowed paths defined in ALLOWED_TRANSITIONS
  #
  # Allow any status for new records
  def validate_status_transitions
    # New records can have any status
    return if new_record?

    # Get the status values before and after the change
    old_status = status_was.to_sym if status_was.present?
    new_status = status.to_sym

    return if old_status.nil?

    # Check if transition is allowed
    unless ALLOWED_TRANSITIONS[old_status].include?(new_status)
      errors.add(
        :status,
        :invalid_transition,
        message: "can't transition from '#{old_status}' to '#{new_status}'",
        allowed_transitions: ALLOWED_TRANSITIONS[old_status].join(", ")
      )
    end
  end
end
