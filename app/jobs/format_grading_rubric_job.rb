# frozen_string_literal: true

# Job to format the grading rubric asynchronously
#
# This job is triggered when a new GradingTask is created and it formats
# the grading rubric using the GradingRubricFormatterService.
class FormatGradingRubricJob < ApplicationJob
  queue_as :formatting

  def perform(grading_task_id)
    grading_task = GradingTask.find_by(id: grading_task_id)
    return unless grading_task

    # Use RetryHandler to handle API overload errors with exponential backoff
    RetryHandler.with_retry(error_class: ApiOverloadError, max_retries: 3, base_delay: 2) do
      formatter = GradingRubricFormatterService.new
      formatter.format(grading_task)

      # Reload the grading task to ensure we have the latest data
      grading_task.reload

      # Broadcast the update to the UI
      Turbo::StreamsChannel.broadcast_replace_to(
        "grading_task_#{grading_task.id}",
        target: "grading_rubric_container_#{grading_task.id}",
        partial: "grading_tasks/grading_rubric_container",
        locals: { grading_task: grading_task }
      )
    end
  rescue => e
    Rails.logger.error("FormatGradingRubricJob failed with error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
