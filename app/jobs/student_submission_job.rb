# frozen_string_literal: true

# Job to process a student submission asynchronously
#
# This job is triggered when a student submission is created via the ProcessGradingTaskCommand
# and it delegates the actual processing to the ProcessStudentSubmissionCommand.
class StudentSubmissionJob < ApplicationJob
  queue_as :student_submissions

  # Process a student submission by its ID
  #
  # @param student_submission_id [Integer] The ID of the student submission to process
  def perform(student_submission_id)
    # Call the command to process the student submission
    command = ProcessStudentSubmissionCommand.new(student_submission_id: student_submission_id).call

    if command.failure?
      # Log any errors that occurred during processing
      Rails.logger.error("StudentSubmissionJob failed: #{command.errors.join(', ')}")
    end

    # Return the command
    command
  rescue => e
    # Log the unhandled error
    Rails.logger.error("StudentSubmissionJob failed with unhandled error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    # Update the submission status to failed
    submission = StudentSubmission.find_by(id: student_submission_id)
    if submission
      StatusManager.transition_submission(
        submission,
        :failed,
        feedback: "Failed to complete grading: #{e.message}"
      )
    end

    # Return nil to indicate failure
    nil
  end
end
