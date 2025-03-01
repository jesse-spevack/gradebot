# frozen_string_literal: true

# Job to process a grading task asynchronously
#
# This job is triggered when a new GradingTask is created and it delegates
# the actual processing to the ProcessGradingTaskCommand.
class GradingTaskJob < ApplicationJob
  queue_as :default

  # Process a grading task by its ID
  #
  # @param grading_task_id [Integer] The ID of the grading task to process
  def perform(grading_task_id)
    # Call the command to process the grading task
    command = ProcessGradingTaskCommand.new(grading_task_id: grading_task_id).call

    if command.failure?
      # Log any errors that occurred during processing
      Rails.logger.error("GradingTaskJob failed: #{command.errors.join(', ')}")
    end
  end
end
