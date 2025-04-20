class GradingTask < ApplicationRecord
  has_prefix_id :gt
  # Use optimistic locking
  # This model has a lock_version column for this purpose

  # Constants
  FEEDBACK_TONE = {
    encouraging: "Encouraging",
    neutral: "Neutral/Objective",
    critical: "Critical"
  }.freeze

  # Associations
  belongs_to :rubric, optional: true
  belongs_to :user

  has_many :document_selections, dependent: :destroy
  has_many :student_submissions, dependent: :destroy

  has_one :assignment_prompt, dependent: :destroy
  has_one :grading_task_summary, dependent: :destroy
  has_one :raw_rubric, dependent: :destroy

  accepts_nested_attributes_for :assignment_prompt

  # Enums
  enum :status, {
    pending: 0,                   # Pending
    processing: 10,               # Processing
    completed: 20,                # Completed
    failed: 30                    # Failed
  }

  # Validations
  validates :feedback_tone, inclusion: { in: FEEDBACK_TONE.keys.map(&:to_s) }, allow_nil: true
end
