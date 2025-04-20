# frozen_string_literal: true

# Job to process a grading task asynchronously
#
# This job is triggered when a new GradingTask is created in the grading task controller and it delegates
# the actual processing to the GradingTask::ProcessorService.
class GradingTaskJob < ApplicationJob
  queue_as :default

  # Process a grading task by its ID
  #
  # @param grading_task_id [Integer] The ID of the grading task to process
  def perform(grading_task_id)
    Rails.logger.info("Starting GradingTaskJob for grading task #{grading_task_id}")

    begin
      # Call the service to process the grading task
      GradingTask::ProcessorService.process(grading_task_id)
      Rails.logger.info("GradingTaskJob completed successfully for grading task #{grading_task_id}")
    rescue GradingTask::ProcessorService::Error => e
      # Log any errors that occurred during processing
      Rails.logger.error("GradingTaskJob failed: #{e.message}")
    end
  end
end
