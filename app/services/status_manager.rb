# frozen_string_literal: true

# Service for managing status transitions and calculations
#
# This class centralizes all status management logic for GradingTask and StudentSubmission,
# providing a single source of truth and simplified interface for status operations.
class StatusManager
  # Determine the current status of a grading task based on its submissions
  # @param grading_task [GradingTask] the grading task to check
  # @return [Symbol] the calculated status
  def self.calculate_grading_task_status(grading_task)
    # Get counts for different statuses
    submission_counts = count_submissions_by_status(grading_task)
    total = submission_counts.values.sum

    # Determine status based on submission counts
    if total.zero?
      :created
    elsif submission_counts[:processing] > 0
      :submissions_processing
    elsif submission_counts[:pending] > 0
      :submissions_processing
    elsif submission_counts[:failed] > 0
      :completed_with_errors
    else
      :completed
    end
  end

  # Update a grading task's status based on its submissions
  # @param grading_task [GradingTask] the grading task to update
  # @return [Boolean] true if the status was updated, false otherwise
  def self.update_grading_task_status(grading_task)
    # Only update status if we're in the submissions processing phase or later
    return true unless grading_task.rubric_processed? ||
                       grading_task.submissions_processing? ||
                       grading_task.completed? ||
                       grading_task.completed_with_errors?

    submission_counts = count_submissions_by_status(grading_task)
    total = submission_counts.values.sum

    # If no submissions, nothing to do
    return true if total.zero?

    # If any submissions are processing, ensure we're in submissions_processing state
    if submission_counts[:processing] > 0 && !grading_task.submissions_processing?
      Rails.logger.info("Starting submissions processing for grading task #{grading_task.id}")
      return grading_task.start_submissions_processing!
    end

    # If all submissions are completed or failed
    if submission_counts[:pending] == 0 && submission_counts[:processing] == 0
      # If we're already in completed or completed_with_errors state, nothing to do
      return true if grading_task.completed? || grading_task.completed_with_errors?

      # If any submissions failed, mark as completed with errors
      if submission_counts[:failed] > 0
        Rails.logger.info("Marking grading task #{grading_task.id} as completed with errors")
        return grading_task.mark_completed_with_errors!
      else
        # All submissions completed successfully
        Rails.logger.info("Completing processing for grading task #{grading_task.id}")
        return grading_task.complete_processing!
      end
    end

    # If we have pending submissions but none processing, we're waiting for processing to start
    if submission_counts[:pending] > 0 && submission_counts[:processing] == 0
      # Make sure we're in submissions_processing state
      return true if grading_task.submissions_processing?

      Rails.logger.info("Starting submissions processing for grading task #{grading_task.id}")
      return grading_task.start_submissions_processing!
    end

    # No state change needed
    true
  end

  # Check if a transition is allowed for a student submission
  # @param submission [StudentSubmission] the submission to check
  # @param new_status [Symbol, String] the desired new status
  # @return [Boolean] true if the transition is allowed, false otherwise
  def self.can_transition_submission?(submission, new_status)
    new_status = new_status.to_sym if new_status.is_a?(String)

    # Define allowed transitions
    allowed_transitions = {
      pending: [ :processing, :failed ],
      processing: [ :completed, :failed ],
      completed: [],
      failed: []
    }

    # Special case for retry
    return true if submission.failed? && new_status == :pending

    # Check if transition is allowed
    allowed_transitions[submission.status.to_sym].include?(new_status)
  end

  # Transition a student submission to a new status
  # @param submission [StudentSubmission] the submission to transition
  # @param new_status [Symbol, String] the desired new status
  # @param attributes [Hash] additional attributes to update
  # @return [Boolean] true if the transition was successful, false otherwise
  def self.transition_submission(submission, new_status, attributes = {})
    # Add debug logging
    Rails.logger.debug("StatusManager: Starting transition for submission #{submission.id} from #{submission.status} to #{new_status}")
    Rails.logger.debug("StatusManager: Attributes passed to transition: #{attributes.inspect}")

    # Check for nil attributes that could cause problems
    attributes.each do |key, value|
      if value.nil?
        Rails.logger.debug("StatusManager: WARNING - nil value for key '#{key}'")
      elsif value.is_a?(Hash)
        value.each do |sub_key, sub_value|
          Rails.logger.debug("StatusManager: WARNING - nil sub-value for key '#{key}.#{sub_key}'") if sub_value.nil?
        end
      end
    end

    new_status = new_status.to_sym if new_status.is_a?(String)

    # Skip if status isn't changing
    return true if submission.status.to_sym == new_status

    # Check if transition is allowed
    unless can_transition_submission?(submission, new_status)
      Rails.logger.error("Invalid transition from #{submission.status} to #{new_status} for submission #{submission.id}")
      return false
    end

    # Update submission within transaction
    ActiveRecord::Base.transaction do
      # Ensure metadata is a hash if it's being updated
      if attributes[:metadata]
        Rails.logger.debug("StatusManager: Metadata present in attributes: #{attributes[:metadata].inspect}")
        attributes[:metadata] = {} unless attributes[:metadata].is_a?(Hash)
      end

      # Log the final attributes being used for the update
      Rails.logger.debug("StatusManager: Final attributes for update: #{attributes.merge(status: new_status).inspect}")

      # Update the submission
      success = submission.update(attributes.merge(status: new_status))

      Rails.logger.debug("StatusManager: Update #{success ? 'succeeded' : 'failed'}")
      unless success
        Rails.logger.error("StatusManager: Update errors: #{submission.errors.full_messages.join(', ')}")
      end

      # If the update was successful, broadcast the submission update
      broadcast_student_submission_update(submission) if success

      # Update the grading task status if submission was updated
      update_grading_task_status(submission.grading_task) if success

      success
    end
  end

  # Retry a failed submission by resetting it to pending
  # @param submission [StudentSubmission] the submission to retry
  # @return [Boolean] true if the retry was successful, false otherwise
  def self.retry_submission(submission)
    return false unless submission.failed?

    transition_submission(submission, :pending)
  end

  # Calculate the progress percentage for a grading task
  # @param grading_task [GradingTask] the grading task to calculate progress for
  # @return [Integer] the progress percentage (0-100)
  def self.calculate_progress_percentage(grading_task)
    submission_counts = count_submissions_by_status(grading_task)
    total = submission_counts.values.sum

    return 0 if total.zero?

    completed = submission_counts[:completed] + submission_counts[:failed]
    ((completed * 100.0) / total).to_i
  end

  # Get counts of submissions by status for a grading task
  # @param grading_task [GradingTask] the grading task to count submissions for
  # @return [Hash] counts of submissions by status
  def self.count_submissions_by_status(grading_task)
    # Query the submissions directly to avoid any caching issues
    pending_count = grading_task.student_submissions.where(status: StudentSubmission.statuses[:pending]).count
    processing_count = grading_task.student_submissions.where(status: StudentSubmission.statuses[:processing]).count
    completed_count = grading_task.student_submissions.where(status: StudentSubmission.statuses[:completed]).count
    failed_count = grading_task.student_submissions.where(status: StudentSubmission.statuses[:failed]).count

    {
      pending: pending_count,
      processing: processing_count,
      completed: completed_count,
      failed: failed_count
    }
  end

  # Broadcast an update to a student submission
  # @param submission [StudentSubmission] the submission to broadcast
  def self.broadcast_student_submission_update(submission)
    # Delegate to the SubmissionBroadcaster service
    SubmissionBroadcaster.new(submission).broadcast_update
  end

  private

  # Broadcast an update to a grading task
  # @param grading_task [GradingTask] the grading task to broadcast
  def self.broadcast_grading_task_update(grading_task)
    # Find the most recent submission for this grading task
    submission = grading_task.student_submissions.order(updated_at: :desc).first

    # If there's a submission, use the SubmissionBroadcaster to update the task components
    if submission
      broadcaster = SubmissionBroadcaster.new(submission)
      broadcaster.broadcast_update
    end
  end
end
