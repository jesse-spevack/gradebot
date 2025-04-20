# frozen_string_literal: true

# This service processes a grading task in the background.
# It coordinates:
# 1. Rubric generation (via Rubric::GeneratorService)
# 2. Status transitions
# 3. Transaction management to ensure data consistency
class GradingTask::ProcessorService
  # Error classes
  class Error < StandardError; end
  class ProcessingError < Error; end

  # Process a grading task
  # @param grading_task_id [Integer] The ID of the grading task to process
  # @return [GradingTask] The processed grading task
  def self.process(grading_task_id)
    new(grading_task_id).process
  end

  # Initialize with a grading task ID
  # @param grading_task_id [Integer] The ID of the grading task to process
  def initialize(grading_task_id)
    @grading_task_id = grading_task_id
  end

  # Process the grading task
  # @return [GradingTask] The processed grading task
  def process
    Rails.logger.info("Starting to process grading task #{@grading_task_id}")

    begin
      # 1. Find the grading task
      grading_task = find_grading_task
      return nil unless grading_task

      # 2. Transition grading task to processing state
      GradingTask::StatusManagerService.transition_to_processing(grading_task)

      # 3. Process the rubric if needed
      process_rubric(grading_task) if grading_task.rubric&.pending?

      grading_task.reload
    rescue StandardError => e
      Rails.logger.error("Error processing grading task #{@grading_task_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Mark the grading task as failed
      mark_as_failed(e.message)

      # Re-raise a wrapped error
      raise ProcessingError, "Processing of grading task #{@grading_task_id} failed: #{e.message}"
    end
  end

  private

  # Find the grading task
  # @return [GradingTask] The grading task to process
  def find_grading_task
    grading_task = GradingTask.find_by(id: @grading_task_id)

    if grading_task.nil?
      Rails.logger.error("Grading task not found with ID: #{@grading_task_id}")
      return nil
    end

    grading_task
  end

  # Process the rubric for the grading task
  # @param grading_task [GradingTask] The grading task to process
  # @return [Rubric] The processed rubric
  def process_rubric(grading_task)
    Rails.logger.info("Processing rubric for grading task #{grading_task.id}")

    # 1. Update rubric status to processing
    Rubric::StatusManagerService.transition_to_processing(grading_task.rubric)

    # Broadcast the processing state to update UI in real-time
    Rubric::BroadcasterService.broadcast(grading_task.rubric)

    # 2. Generate the rubric
    rubric = Rubric::GeneratorService.generate(
      assignment_prompt: grading_task.assignment_prompt,
      grading_task: grading_task,
      rubric: grading_task.rubric
    )

    # 3. Update rubric status to complete
    Rubric::StatusManagerService.transition_to_complete(rubric)

    # Broadcast the completed state to update UI in real-time
    Rubric::BroadcasterService.broadcast(rubric)

    rubric
  rescue StandardError => e
    # Mark the rubric as failed
    Rails.logger.error("Error processing rubric: #{e.message}")
    if grading_task&.rubric
      Rubric::StatusManagerService.transition_to_failed(grading_task.rubric, e.message)

      # Broadcast the failed state to update UI in real-time
      Rubric::BroadcasterService.broadcast(grading_task.rubric)
    end

    # Re-raise the exception
    raise
  end

  # Mark the grading task as failed
  # @param message [String] The error message
  # @return [Boolean] Whether the update was successful
  def mark_as_failed(message)
    grading_task = find_grading_task
    return false unless grading_task

    Rails.logger.info("Marking grading task #{grading_task.id} as failed: #{message}")
    GradingTask::StatusManagerService.transition_to_failed(grading_task, message)
  end
end
