# frozen_string_literal: true

# Service for managing status transitions and calculations
#
# This class centralizes all status management logic for GradingTask and StudentSubmission,
# providing a single source of truth and simplified interface for status operations.
class StatusManager
  # Determine the current status of a grading task based on its submissions
  # @param grading_task [GradingTask] the grading task to check
  # @return [Symbol] the calculated status (:pending, :processing, :completed, :completed_with_errors)
  def self.calculate_grading_task_status(grading_task)
    # Get counts for different statuses
    submission_counts = count_submissions_by_status(grading_task)
    total = submission_counts.values.sum

    # Determine status based on submission counts
    if total.zero?
      :pending
    elsif submission_counts[:processing] > 0
      :processing
    elsif submission_counts[:pending] > 0
      :pending
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
    new_status = calculate_grading_task_status(grading_task)

    # Only update if the status has changed
    return true if grading_task.status.to_sym == new_status

    Rails.logger.info("Updating grading task #{grading_task.id} status from #{grading_task.status} to #{new_status}")
    success = grading_task.update(status: new_status)

    # Broadcast the update to all connected clients if the update was successful
    broadcast_grading_task_update(grading_task) if success

    success
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

  private

  # Broadcast an update to a grading task
  # @param grading_task [GradingTask] the grading task to broadcast
  def self.broadcast_grading_task_update(grading_task)
    # Reload to ensure we have the latest data including associations
    grading_task.reload

    # Get the student submissions
    student_submissions = grading_task.student_submissions.order(created_at: :desc)

    # Option 1: Broadcast to the entire grading task (less efficient but simpler)
    # This is kept for potential backwards compatibility
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{grading_task.id}",
      target: dom_id(grading_task),
      partial: "grading_tasks/grading_task",
      locals: {
        grading_task: grading_task,
        student_submissions: student_submissions
      }
    )

    # Option 2: Broadcast to individual components (more efficient)
    broadcast_task_components(grading_task, student_submissions)
  end

  # Broadcast updates to individual components of a grading task
  # @param grading_task [GradingTask] the grading task to broadcast
  # @param student_submissions [ActiveRecord::Relation] the submissions for this task
  def self.broadcast_task_components(grading_task, student_submissions)
    # 1. Update the status badge
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{grading_task.id}",
      target: "#{dom_id(grading_task)}_status_badge",
      partial: "grading_tasks/task_status_badge",
      locals: { grading_task: grading_task }
    )

    # 2. Update the progress metrics
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{grading_task.id}",
      target: "#{dom_id(grading_task)}_progress_metrics",
      partial: "grading_tasks/progress_metrics",
      locals: {
        grading_task: grading_task,
        student_submissions: student_submissions
      }
    )

    # 3. Update the submission counts
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{grading_task.id}",
      target: "#{dom_id(grading_task)}_submission_counts",
      partial: "grading_tasks/submission_counts",
      locals: { student_submissions: student_submissions }
    )

    # 4. Send a full update for the progress section to ensure it catches all changes
    # This helps prevent race conditions where individual updates might be missed
    Turbo::StreamsChannel.broadcast_update_to(
      "grading_task_#{grading_task.id}",
      target: "progress_section_#{dom_id(grading_task)}",
      partial: "grading_tasks/progress_section",
      locals: {
        grading_task: grading_task,
        student_submissions: student_submissions
      }
    )
  end

  # Broadcast an update to a student submission
  # @param submission [StudentSubmission] the submission to broadcast
  def self.broadcast_student_submission_update(submission)
    # Reload to ensure we have the latest data
    submission.reload

    # Get the parent grading task
    grading_task = submission.grading_task

    # Broadcast the main submission content
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{submission.grading_task_id}",
      target: dom_id(submission),
      partial: "student_submissions/student_submission_content",
      locals: { student_submission: submission }
    )

    # Broadcast to the table row separately
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{submission.grading_task_id}",
      target: "#{dom_id(submission)}_table_row",
      partial: "student_submissions/table_row",
      locals: { submission: submission }
    )

    # Broadcast to the card separately
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{submission.grading_task_id}",
      target: "#{dom_id(submission)}_card",
      partial: "student_submissions/submission_card",
      locals: { submission: submission }
    )

    # Always broadcast to the detail views, as someone might be viewing them
    # and to ensure statuses are always in sync
    # Broadcast to the submission detail view (on the student submission page)
    Turbo::StreamsChannel.broadcast_replace_to(
      "student_submission_#{submission.id}",
      target: "#{dom_id(submission)}_detail",
      partial: "student_submissions/detail",
      locals: { student_submission: submission }
    )

    # Also broadcast to the header status section of the submission detail view
    Turbo::StreamsChannel.broadcast_replace_to(
      "student_submission_#{submission.id}",
      target: "header_status",
      partial: "student_submissions/header_status",
      locals: { student_submission: submission }
    )

    # Also update the grading task components since a submission status change
    # affects the task's progress and counts
    broadcast_task_components(
      grading_task,
      grading_task.student_submissions.order(created_at: :desc)
    )
  end

  # Generate a DOM ID for a record (same as ApplicationController#dom_id)
  # @param record [ActiveRecord::Base] the record to generate an ID for
  # @return [String] the DOM ID
  def self.dom_id(record)
    ActionView::RecordIdentifier.dom_id(record)
  end
end
