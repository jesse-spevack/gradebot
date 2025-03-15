# frozen_string_literal: true

require "bigdecimal"

# Command to calculate the total cost of a grading task
#
# This command calculates the total cost of a grading task by summing up
# all the costs logged in LLMCostLog for both the grading task and its student submissions.
class CalculateGradingTaskCostCommand < BaseCommand
  # Make grading_task explicitly available in the class
  attr_reader :grading_task

  # Initialize the command
  # @param grading_task [GradingTask] The grading task object
  def initialize(grading_task:)
    super
  end

  private

  # Execute the command logic
  # @return [BigDecimal] The total cost of the grading task
  def execute
    unless grading_task.is_a?(GradingTask)
      @errors << "Invalid grading task: must be a GradingTask object"
      return nil
    end

    Rails.logger.debug "Calculating costs for grading task #{grading_task.id}"

    # Calculate total cost using a single query
    total_cost = calculate_total_cost

    Rails.logger.debug "Total cost for grading task #{grading_task.id}: #{total_cost}"
    total_cost
  end

  # Calculate the total cost for a grading task and its submissions
  # @return [BigDecimal] The total cost
  def calculate_total_cost
    # Get all submission IDs for this grading task
    submission_ids = grading_task.student_submissions.pluck(:id)

    # Build a query that includes both the grading task and its submissions
    query = LLMCostLog.where(trackable: grading_task)

    # Add submission costs if there are any submissions
    unless submission_ids.empty?
      query = query.or(
        LLMCostLog.where(
          trackable_type: "StudentSubmission",
          trackable_id: submission_ids
        )
      )
    end

    # Sum up all costs and convert to BigDecimal for precision
    BigDecimal(query.sum(:cost).to_s)
  end
end
