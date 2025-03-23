# frozen_string_literal: true

class ProcessGradingTaskCommand < CommandBase
  def execute
    grading_task = find_grading_task
    return nil unless grading_task

    begin
      grading_task.start_assignment_processing!

      grading_task
    rescue StandardError => e
      handle_error(e.message)
      grading_task.fail! if grading_task
      nil
    end
  end

  private

  def find_grading_task
    grading_task = GradingTask.find_by(id: grading_task_id)
    unless grading_task
      handle_error("Grading task not found with ID: #{grading_task_id}")
      return nil
    end

    Rails.logger.info("Processing grading task #{grading_task_id} for folder: #{grading_task.display_name}")
    grading_task
  end

  def handle_error(message)
    Rails.logger.error("Error processing grading task #{grading_task_id}: #{message}")
    @errors << message
  end
end
