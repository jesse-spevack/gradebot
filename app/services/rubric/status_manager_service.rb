# frozen_string_literal: true

# This service manages status transitions for Rubric objects.
# It centralizes status validation and transition logic, ensuring
# consistent state management and broadcasting of state changes.
class Rubric::StatusManagerService
  # Error raised when an invalid status transition is attempted
  class InvalidTransitionError < StandardError; end

  # Valid status transitions
  VALID_TRANSITIONS = {
    pending: [ :processing ],
    processing: [ :complete, :failed ],
    failed: [ :pending ],
    complete: []
  }.freeze

  # Transition a rubric to the processing status
  # @param rubric [Rubric] The rubric to update
  # @return [Boolean] Whether the update was successful
  def self.transition_to_processing(rubric)
    new(rubric).transition_to(:processing)
  end

  # Transition a rubric to the complete status
  # @param rubric [Rubric] The rubric to update
  # @return [Boolean] Whether the update was successful
  def self.transition_to_complete(rubric)
    new(rubric).transition_to(:complete)
  end

  # Transition a rubric to the failed status
  # @param rubric [Rubric] The rubric to update
  # @param error_message [String] Optional error message to log
  # @return [Boolean] Whether the update was successful
  def self.transition_to_failed(rubric, error_message = nil)
    new(rubric).transition_to(:failed, error_message)
  end

  # Transition a rubric to the pending status
  # @param rubric [Rubric] The rubric to update
  # @return [Boolean] Whether the update was successful
  def self.transition_to_pending(rubric)
    new(rubric).transition_to(:pending)
  end

  # Initialize a new instance of the StatusManagerService
  # @param rubric [Rubric] The rubric to manage
  def initialize(rubric)
    @rubric = rubric&.reload
  end

  # Transition a rubric to a specified status
  # @param status [Symbol, String] The target status
  # @param error_message [String] Optional error message for failed status
  # @return [Boolean] Whether the update was successful
  def transition_to(status, error_message = nil)
    return false if @rubric.nil?

    current_status = @rubric.status.to_sym

    # Validate the transition
    unless valid_transition?(current_status, status)
      error_msg = "Invalid transition from #{current_status} to #{status}"
      Rails.logger.error(error_msg)
      raise InvalidTransitionError, error_msg
    end

    Rails.logger.info("Transitioning rubric #{@rubric.id} from #{current_status} to #{status}")

    if status == "failed" && error_message.present?
      Rails.logger.error("Rubric #{@rubric.id} failed: #{error_message}")
    end

    # Update the status
    result = @rubric.update(status: status)

    result
  end

  private

  # Check if a status transition is valid
  # @param from_status [String] The current status
  # @param to_status [String] The target status
  # @return [Boolean] Whether the transition is valid
  def valid_transition?(from_status, to_status)
    # If current and target are the same, it's valid (no-op transition)
    return true if from_status == to_status

    # Check if the transition is in the valid transitions map
    VALID_TRANSITIONS.key?(from_status) && VALID_TRANSITIONS[from_status].include?(to_status)
  end
end
