# frozen_string_literal: true

# Job to process a student submission asynchronously
class StudentSubmissionJob < ApplicationJob
  queue_as :student_submissions

  def perform(student_submission_id)
    student_submission = StudentSubmission.find_by(id: student_submission_id)
    StudentSubmission::Processor.process(student_submission: student_submission)
  rescue => e
    Rails.logger.error("StudentSubmissionJob failed with unhandled error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    student_submission = StudentSubmission.find_by(id: student_submission_id)
    if student_submission
      StudentSubmission::StatusUpdater.transition_student_submission_to_failed(
        student_submission,
        { feedback: "Failed to complete grading: #{e.message}" }
      )
    end
  end
end
