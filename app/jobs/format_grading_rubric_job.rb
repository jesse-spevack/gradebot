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

    # Ensure we're in the correct state
    return unless grading_task.rubric_processing?

    begin
      formatter = GradingRubricFormatterService.new
      formatter.format(grading_task)

      # Reload the grading task to ensure we have the latest data
      grading_task.reload

      # Broadcast the update to the UI
      broadcast_update(grading_task)

      # Transition to the next state
      grading_task.complete_rubric_processing!
    rescue ActiveRecord::StaleObjectError => e
      # Log the error but don't re-raise it
      Rails.logger.error("FormatGradingRubricJob encountered a stale object error: #{e.message}")

      # Reload and try to broadcast anyway
      begin
        grading_task.reload
        broadcast_update(grading_task)
      rescue => broadcast_error
        Rails.logger.error("Failed to broadcast after stale object error: #{broadcast_error.message}")
      end

      # Try to transition to the next state
      begin
        grading_task.complete_rubric_processing!
      rescue => transition_error
        Rails.logger.error("Failed to transition state after stale object error: #{transition_error.message}")
        grading_task.fail!
      end
    rescue => e
      Rails.logger.error("FormatGradingRubricJob failed with error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      grading_task.fail!
    end
  end

  private

  # Broadcast the update to the UI
  # @param grading_task [GradingTask] The grading task to broadcast
  def broadcast_update(grading_task)
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{grading_task.id}",
      target: "grading_rubric_container_#{grading_task.id}",
      partial: "grading_tasks/grading_rubric_container",
      locals: { grading_task: grading_task }
    )
  end
end
