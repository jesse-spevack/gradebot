# frozen_string_literal: true

class StudentSubmission < ApplicationRecord
  has_prefix_id :ss
  # Use optimistic locking
  # This model has a lock_version column for this purpose

  ALLOWED_TRANSITIONS = {
    pending: [ :processing, :failed ],
    processing: [ :completed, :failed ],
    completed: [],
    failed: []
  }.freeze

  belongs_to :grading_task
  belongs_to :document_selection, optional: true

  has_many :document_actions
  has_many :student_submission_checks, dependent: :destroy
  has_many :strengths, as: :recordable, dependent: :destroy
  has_many :opportunities, as: :recordable, dependent: :destroy
  has_many :rubric_criterion_scores, dependent: :destroy

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

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

  # Returns the document title if available
  # @return [String] Document title or a default value
  def document_title
    document_selection.name
  end

  def last_post_feedback_action
    document_actions.post_feedback.most_recent.first
  end

  def feedback_posted?
    document_actions.completed_post_feedback.exists?
  end
end
