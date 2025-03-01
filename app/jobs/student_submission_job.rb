# frozen_string_literal: true

# Job to process a student submission asynchronously
#
# This job is triggered when a student submission is created via the ProcessGradingTaskCommand
# and it delegates the actual processing to the ProcessStudentSubmissionCommand.
class StudentSubmissionJob < ApplicationJob
  queue_as :default

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
  end
end
