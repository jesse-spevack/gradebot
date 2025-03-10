# frozen_string_literal: true

# Service to handle student submission status transitions
class SubmissionStatusUpdater
  # @param submission [StudentSubmission] The submission to update
  def initialize(submission)
    @submission = submission
  end

  # Transitions the submission to a new status
  # @param state [Symbol] The state to transition to (:processing, :completed, :failed)
  # @param attributes [Hash] Additional attributes to update
  # @return [Boolean] True if the transition was successful, false otherwise
  def transition_to(state, attributes = {})
    Rails.logger.info("Transitioning submission #{@submission.id} to #{state}")
    StatusManager.transition_submission(@submission, state, attributes)
  rescue => e
    Rails.logger.error("Error transitioning submission #{@submission.id} to #{state}: #{e.message}")
    false
  end
end
