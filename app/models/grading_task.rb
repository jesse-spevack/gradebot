class GradingTask < ApplicationRecord
  # Use optimistic locking
  # This model has a lock_version column for this purpose

  # Constants - keep these for reference and clarity
  STATUS_PENDING = 0
  STATUS_PROCESSING = 1
  STATUS_COMPLETED = 2
  STATUS_COMPLETED_WITH_ERRORS = 3

  # Associations
  belongs_to :user
  has_many :student_submissions, dependent: :destroy

  # Enums
  enum :status, {
    pending: STATUS_PENDING,
    processing: STATUS_PROCESSING,
    completed: STATUS_COMPLETED,
    completed_with_errors: STATUS_COMPLETED_WITH_ERRORS
  }

  # Validations
  validates :assignment_prompt, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :grading_rubric, presence: true, length: { minimum: 10, maximum: 3000 }
  validates :folder_id, presence: true
  validates :folder_name, presence: true

  # Callbacks
  after_create :enqueue_processing_job

  # Instance methods

  # Calculate the progress percentage based on completed and failed submissions
  # @return [Integer] Percentage of submissions that are completed or failed
  def progress_percentage
    # Use the StatusManager service to calculate progress
    StatusManager.calculate_progress_percentage(self)
  end

  private

  # Enqueue a background job to process this grading task
  def enqueue_processing_job
    GradingTaskJob.perform_later(id)
  end
end
