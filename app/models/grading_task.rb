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
    created: 0,                    # Initial state
    assignment_processing: 10,     # Assignment prompt is being processed
    assignment_processed: 20,      # Assignment prompt processing completed
    rubric_processing: 30,         # Rubric is being processed
    rubric_processed: 40,          # Rubric processing completed
    submissions_processing: 50,    # Student submissions are being processed
    completed: 60,                 # All processing is finished
    completed_with_errors: 65,     # Processing finished but with some errors
    failed: 70                     # An error occurred during processing
  }

  # Validations
  validates :assignment_prompt, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :grading_rubric, presence: true, length: { minimum: 10, maximum: 3000 }
  validates :folder_id, presence: true
  validates :folder_name, presence: true
  validate :validate_status_transition, if: :status_changed?

  # Callbacks
  after_create :enqueue_processing_job

  # Instance methods

  # Calculate the progress percentage based on completed and failed submissions
  # @return [Integer] Percentage of submissions that are completed or failed
  def progress_percentage
    # Use the StatusManager service to calculate progress
    StatusManager.calculate_progress_percentage(self)
  end

  # User-friendly status label
  def status_label
    case status.to_sym
    when :created then "Created"
    when :assignment_processing then "Processing Assignment..."
    when :assignment_processed then "Assignment Processed"
    when :rubric_processing then "Processing Rubric..."
    when :rubric_processed then "Rubric Processed"
    when :submissions_processing then "Processing Submissions..."
    when :completed then "Completed"
    when :completed_with_errors then "Completed with Errors"
    when :failed then "Failed"
    end
  end

  # State transition methods
  def start_assignment_processing!
    return false unless may_start_assignment_processing?

    update!(status: :assignment_processing)
    # Broadcast status update
    broadcast_status_update
    # Enqueue the job
    FormatAssignmentPromptJob.perform_later(id)
    true
  end

  def complete_assignment_processing!
    return false unless may_complete_assignment_processing?

    update!(status: :assignment_processed)
    # Broadcast status update
    broadcast_status_update(include_assignment_prompt: true)
    # Start the next step
    start_rubric_processing!
    true
  end

  def start_rubric_processing!
    return false unless may_start_rubric_processing?

    update!(status: :rubric_processing)
    # Broadcast status update
    broadcast_status_update
    # Enqueue the job
    FormatGradingRubricJob.perform_later(id)
    true
  end

  def complete_rubric_processing!
    return false unless may_complete_rubric_processing?

    update!(status: :rubric_processed)
    # Broadcast status update
    broadcast_status_update(include_grading_rubric: true)
    # Start the next step
    start_submissions_processing!
    true
  end

  def start_submissions_processing!
    return false unless may_start_submissions_processing?

    update!(status: :submissions_processing)
    # Broadcast status update
    broadcast_status_update
    # Enqueue the job
    StudentSubmissionsForGradingTaskJob.perform_later(id)
    true
  end

  def complete_processing!
    return false unless may_complete_processing?

    update!(status: :completed)
    # Broadcast status update
    broadcast_status_update
    true
  end

  def fail!
    update!(status: :failed)
    # Broadcast status update
    broadcast_status_update
    true
  end

  # Mark as completed with errors
  def mark_completed_with_errors!
    return false unless may_complete_processing?

    update!(status: :completed_with_errors)
    # Broadcast status update
    broadcast_status_update
    true
  end

  # Permission methods to check if transitions are allowed
  def may_start_assignment_processing?
    created?
  end

  def may_complete_assignment_processing?
    assignment_processing?
  end

  def may_start_rubric_processing?
    assignment_processed?
  end

  def may_complete_rubric_processing?
    rubric_processing?
  end

  def may_start_submissions_processing?
    rubric_processed?
  end

  def may_complete_processing?
    submissions_processing?
  end

  private

  # Enqueue a background job to process this grading task
  def enqueue_processing_job
    GradingTaskJob.perform_later(id)
  end

  # Validate that status transitions follow the correct sequence
  def validate_status_transition
    return true if status_was.nil? # New record

    old_status = self.class.statuses[status_was]
    new_status = self.class.statuses[status]

    # Allow transition to failed from any state
    return true if status.to_sym == :failed

    # Allow transition from completed_with_errors to submissions_processing (for retries)
    return true if status_was.to_sym == :completed_with_errors && status.to_sym == :submissions_processing

    # Ensure the new status is higher than the old status (forward progression)
    unless new_status > old_status
      errors.add(:status, "cannot transition from #{status_was} to #{status}")
    end
  end

  # Broadcast status update to the UI
  def broadcast_status_update(include_assignment_prompt: false, include_grading_rubric: false)
    Rails.logger.debug("Broadcasting status update for grading task #{id}")
    broadcaster = GradingTaskBroadcaster.new(self)
    broadcaster.broadcast_grading_task_status_update

    if include_assignment_prompt
      Rails.logger.debug("Broadcasting assignment prompt update for grading task #{id}")
      broadcaster.broadcast_grading_task_assignment_prompt_update
    end

    if include_grading_rubric
      Rails.logger.debug("Broadcasting grading rubric update for grading task #{id}")
      broadcaster.broadcast_grading_task_grading_rubric_update
    end
  end
end
