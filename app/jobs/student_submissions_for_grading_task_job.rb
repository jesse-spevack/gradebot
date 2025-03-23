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
    return unless grading_task&.submissions_processing?

    begin
      student_submissions = StudentSubmission.where(grading_task_id: grading_task_id)

      if student_submissions.empty?
        Rails.logger.warn("No student submissions found for grading task ID: #{grading_task_id}")
        grading_task.complete_processing!
        return
      end

      Rails.logger.info("Processing #{student_submissions.count} student submissions for grading task ID: #{grading_task_id}")

      process_all_student_submissions(student_submissions)

      grading_task.complete_processing!
    rescue => e
      Rails.logger.error("StudentSubmissionsForGradingTaskJob failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      grading_task.fail!
    end
  end

  private

  def process_all_student_submissions(student_submissions)
    student_submissions.each do |student_submission|
      StudentSubmission::Processor.process(student_submission: student_submission)
    end
  end
end
