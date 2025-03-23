# frozen_string_literal: true

# Job to format the grading rubric asynchronously
#
# This job is triggered when a new GradingTask is created and it formats
# the grading rubric using the GradingTask::GradingRubricFormatterService.
class FormatGradingRubricJob < ApplicationJob
  queue_as :formatting

  def perform(grading_task_id)
    grading_task = GradingTask.find_by(id: grading_task_id)
    return unless grading_task

    # Ensure we're in the correct state
    return unless grading_task.rubric_processing?

    begin
      formatter = GradingTask::GradingRubricFormatterService.new
      formatter.format(grading_task)

      # Reload the grading task to ensure we have the latest data
      grading_task.reload

      # Transition to the next state
      grading_task.complete_rubric_processing!
    rescue => e
      Rails.logger.error("FormatGradingRubricJob failed with error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      grading_task.fail! if grading_task
    end
  end
end
