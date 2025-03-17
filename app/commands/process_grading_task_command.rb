# frozen_string_literal: true

# Command to process a grading task by fetching documents and creating submissions
#
# This command takes a grading task ID, fetches documents from the associated
# Google Drive folder, and creates student submissions for each document.
class ProcessGradingTaskCommand < BaseCommand
  attr_reader :grading_task_id

  def initialize(grading_task_id:)
    super
  end

  def execute
    grading_task = find_grading_task
    return nil unless grading_task

    begin
      # Start the workflow
      grading_task.start_assignment_processing!

      # Return the grading task as the result
      grading_task
    rescue StandardError => e
      handle_error(e.message)
      grading_task.fail! if grading_task
      nil
    end
  end

  private

  # Find the grading task by ID
  # @return [GradingTask, nil] The grading task or nil if not found
  def find_grading_task
    grading_task = GradingTask.find_by(id: grading_task_id)
    unless grading_task
      handle_error("Grading task not found with ID: #{grading_task_id}")
      return nil
    end

    Rails.logger.info("Processing grading task #{grading_task_id} for folder: #{grading_task.folder_name}")
    grading_task
  end

  # Handle and log an error
  # @param message [String] The error message
  def handle_error(message)
    Rails.logger.error(message)
    @errors << message
  end
end
