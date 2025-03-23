# frozen_string_literal: true

# Service to handle student submission status transitions
class StudentSubmission::StatusUpdater
  class << self
    def transition_student_submission_to_processing(student_submission, attributes = {})
      new(student_submission).transition_to(:processing, attributes)
    end

    def transition_student_submission_to_completed(student_submission, attributes = {})
      new(student_submission).transition_to(:completed, attributes)
    end

    def transition_student_submission_to_failed(student_submission, attributes = {})
      new(student_submission).transition_to(:failed, attributes)
    end
  end

  def initialize(student_submission)
    @student_submission = student_submission
  end

  # Transitions the submission to a new status
  # @param state [Symbol] The state to transition to (:processing, :completed, :failed)
  # @param attributes [Hash] Additional attributes to update
  # @return [Boolean] True if the transition was successful, false otherwise
  def transition_to(state, attributes = {})
    Rails.logger.info("Transitioning submission #{@student_submission.id} to #{state}")
    StatusManager.transition_submission(@student_submission, state, attributes)
    @student_submission.reload
  rescue => e
    Rails.logger.error("Error transitioning submission #{@student_submission.id} to #{state}: #{e.message}")
    false
  end
end
