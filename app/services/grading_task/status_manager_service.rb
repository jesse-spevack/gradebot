# frozen_string_literal: true

# This service manages status transitions for GradingTask objects.
# It centralizes status validation and transition logic, ensuring
# consistent state management and broadcasting of state changes.
class GradingTask::StatusManagerService
  # Error raised when an invalid status transition is attempted
  class InvalidTransitionError < StandardError; end

  # Valid status transitions
  VALID_TRANSITIONS = {
    pending: [ :processing ],
    processing: [ :completed, :failed ],
    completed: [],
    failed: [ :pending ]
  }.freeze

  # Status labels for display
  STATUS_LABELS = {
    pending: "Pending",
    processing: "Processing",
    completed: "Completed",
    failed: "Failed"
  }.freeze

  # Transition a grading task to the pending status
  # @param grading_task [GradingTask] The grading task to update
  # @return [Boolean] Whether the update was successful
  def self.transition_to_pending(grading_task)
    new(grading_task).transition_to(:pending)
  end

  # Transition a grading task to the processing status
  # @param grading_task [GradingTask] The grading task to update
  # @return [Boolean] Whether the update was successful
  def self.transition_to_processing(grading_task)
    new(grading_task).transition_to(:processing)
  end

  # Transition a grading task to the completed status
  # @param grading_task [GradingTask] The grading task to update
  # @return [Boolean] Whether the update was successful
  def self.transition_to_completed(grading_task)
    new(grading_task).transition_to(:completed)
  end

  # Transition a grading task to the failed status
  # @param grading_task [GradingTask] The grading task to update
  # @param error_message [String] Optional error message to log
  # @return [Boolean] Whether the update was successful
  def self.transition_to_failed(grading_task, error_message = nil)
    new(grading_task).transition_to(:failed, error_message)
  end

  # Initialize a new instance of the StatusManagerService
  # @param grading_task [GradingTask] The grading task to manage
  def initialize(grading_task)
    @grading_task = grading_task
  end

  # Transition a grading task to a specified status
  # @param status [Symbol, String] The target status
  # @param error_message [String] Optional error message for failed status
  # @return [Boolean] Whether the update was successful
  def transition_to(status, error_message = nil)
    return false if @grading_task.nil?

    current_status = @grading_task.status.to_sym
    status = status.to_sym

    # Validate the transition
    unless valid_transition?(current_status, status)
      error_msg = "Invalid transition from #{current_status} to #{status}"
      Rails.logger.error(error_msg)
      raise InvalidTransitionError, error_msg
    end

    Rails.logger.info("Transitioning grading task #{@grading_task.id} from #{current_status} to #{status}")

    if status == :failed && error_message.present?
      Rails.logger.error("Grading task #{@grading_task.id} failed: #{error_message}")
    end

    # Update the status
    result = @grading_task.update(status: status)

    # Broadcast the status change (will be implemented in future task)
    broadcast_status_change if result

    result
  end

  # Get the display label for a status
  # @param status [Symbol, String] The status
  # @return [String] The display label
  def self.label_for(status)
    STATUS_LABELS[status.to_sym] || status.to_s.humanize
  end

  private

  # Check if a status transition is valid
  # @param from_status [Symbol] The current status
  # @param to_status [Symbol] The target status
  # @return [Boolean] Whether the transition is valid
  def valid_transition?(from_status, to_status)
    # If current and target are the same, it's valid (no-op transition)
    return true if from_status == to_status

    # Check if the transition is in the valid transitions map
    VALID_TRANSITIONS.key?(from_status) && VALID_TRANSITIONS[from_status].include?(to_status)
  end

  # Broadcast the status change to the UI
  # This method will be implemented in a future task to integrate with real-time updates
  def broadcast_status_change
    # This is a placeholder for future implementation
    Rails.logger.info("Status change broadcast will be implemented in future task")
  end
end
