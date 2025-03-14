# frozen_string_literal: true

# Job to format the assignment prompt asynchronously
#
# This job is triggered when a new GradingTask is created and it formats
# the assignment prompt using the AssignmentPromptFormatterService.
class FormatAssignmentPromptJob < ApplicationJob
  queue_as :formatting

  def perform(grading_task_id)
    grading_task = GradingTask.find_by(id: grading_task_id)
    return unless grading_task

    # Use RetryHandler to handle API overload errors with exponential backoff
    RetryHandler.with_retry(error_class: ApiOverloadError, max_retries: 3, base_delay: 2) do
      formatter = AssignmentPromptFormatterService.new
      formatter.format(grading_task)

      # Reload the grading task to ensure we have the latest data
      grading_task.reload

      # Broadcast the update to the UI
      Turbo::StreamsChannel.broadcast_replace_to(
        "grading_task_#{grading_task.id}",
        target: "assignment_prompt_container_#{grading_task.id}",
        partial: "grading_tasks/assignment_prompt_container",
        locals: { grading_task: grading_task }
      )
    end
  rescue => e
    Rails.logger.error("FormatAssignmentPromptJob failed with error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
