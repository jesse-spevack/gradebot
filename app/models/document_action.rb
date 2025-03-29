# frozen_string_literal: true

class DocumentAction < ApplicationRecord
  has_prefix_id :da

  belongs_to :student_submission

  enum :action_type, {
    post_feedback: 0
  }

  # Action-type based scopes
  scope :post_feedback, -> { where(action_type: :post_feedback) }

  enum :status, {
    pending: 0, # Initial state
    processing: 1, # Action is being processed
    completed: 2, # Action completed successfully
    failed: 3 # Action failed
  }

  validates :action_type, :student_submission_id, presence: true
  validate :validate_status_transition, if: :status_changed?

  # Query scopes
  scope :most_recent, -> { order(created_at: :desc) }
  scope :completed_post_feedback, -> { post_feedback.where(status: :completed) }

  after_create :enqueue_processing_job

  def start_processing!
    return false unless may_start_processing?

    update!(status: :processing)

    broadcast_status_update
    true
  end

  def complete!
    return false unless may_complete?

    update!(status: :completed, completed_at: Time.current)
    broadcast_status_update
    true
  end

  def fail!(error_message = nil)
    update!(status: :failed, failed_at: Time.current, error_message: error_message)
    broadcast_status_update
    true
  end

  def may_start_processing?
    pending?
  end

  def may_complete?
    processing?
  end

  private

  def enqueue_processing_job
    PostFeedbackJob.perform_later(self.id)
  end

  def validate_status_transition
    return true if status_was.nil?

    old_status = self.class.statuses[status_was]
    new_status = self.class.statuses[status]

    return true if new_status == :failed

    unless new_status > old_status
      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    end
  end

  def broadcast_status_update
    DocumentAction::Broadcaster.new(self).broadcast_update
  end
end
