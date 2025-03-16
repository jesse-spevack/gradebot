# frozen_string_literal: true

# Job to process all student submissions for a grading task
#
# This job is triggered after the grading rubric has been processed
# and processes all student submissions for the given grading task.
class StudentSubmissionsForGradingTaskJob < ApplicationJob
  queue_as :student_submissions

  # Process all student submissions for a grading task
  #
  # @param grading_task_id [Integer] The ID of the grading task
  def perform(grading_task_id)
    grading_task = GradingTask.find_by(id: grading_task_id)
    return unless grading_task

    # Ensure we're in the correct state
    return unless grading_task.submissions_processing?

    begin
      # Get all student submissions for this grading task
      submissions = StudentSubmission.where(grading_task_id: grading_task_id)

      if submissions.empty?
        Rails.logger.warn("No student submissions found for grading task ID: #{grading_task_id}")
        grading_task.complete_processing!
        return
      end

      Rails.logger.info("Processing #{submissions.count} student submissions for grading task ID: #{grading_task_id}")

      # Process each submission
      process_all_submissions(submissions)

      # Mark the grading task as completed
      grading_task.complete_processing!
    rescue => e
      Rails.logger.error("StudentSubmissionsForGradingTaskJob failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      grading_task.fail!
    end
  end

  private

  def process_all_submissions(submissions)
    submissions.each do |submission|
      begin
        command = ProcessStudentSubmissionCommand.new(student_submission_id: submission.id).call

        if command.failure?
          Rails.logger.error("Failed to process student submission #{submission.id}: #{command.errors.join(', ')}")
        end
      rescue => e
        Rails.logger.error("Error processing student submission #{submission.id}: #{e.message}")

        # Update the submission status to failed
        StatusManager.transition_submission(
          submission,
          :failed,
          feedback: "Failed to complete grading: #{e.message}"
        )
      end
    end
  end
end
