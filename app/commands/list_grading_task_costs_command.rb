# frozen_string_literal: true

require "bigdecimal"

# Command to list grading tasks with their associated costs within a date range
#
# This command returns an array of GradingTaskCost objects, each containing
# a grading task and its total cost (including costs from student submissions).
class ListGradingTaskCostsCommand < BaseCommand
  # Make start_date and end_date explicitly available in the class
  attr_reader :start_date, :end_date

  # Initialize the command
  # @param start_date [Date, nil] The start date for the range (optional)
  # @param end_date [Date, nil] The end date for the range (optional)
  def initialize(start_date: nil, end_date: nil)
    super
    @start_date = start_date
    @end_date = end_date
  end

  private

  # Execute the command logic
  # @return [Array<GradingTaskCost>] Array of grading task costs
  def execute
    # Validate date range if both dates are provided
    if start_date && end_date && start_date > end_date
      @errors << "Invalid date range: start date must be before end date"
      return nil
    end

    Rails.logger.debug "Listing grading tasks with costs#{date_range_log_message}"

    # Get grading tasks within the date range
    grading_tasks = find_grading_tasks

    # Calculate costs for each grading task in a single operation
    grading_task_costs = calculate_costs_for_tasks(grading_tasks)

    Rails.logger.debug "Found #{grading_task_costs.length} grading tasks with costs"
    grading_task_costs
  end

  # Find grading tasks within the specified date range
  # @return [Array<GradingTask>] Array of grading tasks
  def find_grading_tasks
    query = GradingTask.all

    # Apply date filters if provided
    query = query.where("created_at >= ?", start_date) if start_date
    query = query.where("created_at <= ?", end_date) if end_date

    # Order by most recent first
    query.order(created_at: :desc)
  end

  # Calculate costs for each grading task
  # @param grading_tasks [Array<GradingTask>] Array of grading tasks
  # @return [Array<GradingTaskCost>] Array of grading task costs
  def calculate_costs_for_tasks(grading_tasks)
    return [] if grading_tasks.empty?

    # Get all grading task IDs
    grading_task_ids = grading_tasks.map(&:id)

    # Get all submissions for these grading tasks in a single query
    submissions = StudentSubmission
      .where(grading_task_id: grading_task_ids)
      .to_a

    # Group submissions by grading task ID
    submissions_by_task = submissions.group_by(&:grading_task_id)

    # Get all costs for grading tasks and submissions
    costs = get_costs_for_trackables(grading_tasks, submissions)

    # Map the results to GradingTaskCost objects
    grading_tasks.map do |task|
      # Get direct costs for the grading task
      task_costs = costs.select { |c| c.trackable_type == "GradingTask" && c.trackable_id == task.id }
      direct_cost = sum_costs(task_costs)

      # Get costs for submissions of this task
      task_submissions = submissions_by_task[task.id] || []
      submission_costs = costs
        .select { |c| c.trackable_type == "StudentSubmission" && task_submissions.map(&:id).include?(c.trackable_id) }
      submission_cost = sum_costs(submission_costs)

      # Total cost is the sum of direct costs and submission costs
      total_cost = direct_cost + submission_cost

      GradingTaskCost.new(grading_task: task, cost: total_cost)
    end
  end

  # Sum costs from an array of cost logs using BigDecimal for precision
  # @param cost_logs [Array<LLMCostLog>] Array of cost logs
  # @return [BigDecimal] Sum of costs
  def sum_costs(cost_logs)
    cost_logs.reduce(BigDecimal("0")) do |sum, log|
      sum + BigDecimal(log.cost.to_s)
    end
  end

  # Get all costs for the given trackable objects
  # @param grading_tasks [Array<GradingTask>] Array of grading tasks
  # @param submissions [Array<StudentSubmission>] Array of student submissions
  # @return [Array<LLMCostLog>] Array of cost logs
  def get_costs_for_trackables(grading_tasks, submissions)
    # Build conditions for the query
    conditions = []

    # Add grading tasks to conditions
    unless grading_tasks.empty?
      conditions << LLMCostLog.where(
        trackable_type: "GradingTask",
        trackable_id: grading_tasks.map(&:id)
      )
    end

    # Add submissions to conditions
    unless submissions.empty?
      conditions << LLMCostLog.where(
        trackable_type: "StudentSubmission",
        trackable_id: submissions.map(&:id)
      )
    end

    # Combine conditions with OR
    query = conditions.reduce { |combined, condition| combined.or(condition) }

    # Apply date filters if provided
    query = query.where("created_at >= ?", start_date) if start_date
    query = query.where("created_at <= ?", end_date) if end_date

    # Execute the query
    query.to_a
  end

  # Generate a log message describing the date range
  # @return [String] Log message
  def date_range_log_message
    if start_date && end_date
      " from #{start_date} to #{end_date}"
    elsif start_date
      " from #{start_date}"
    elsif end_date
      " until #{end_date}"
    else
      " (all time)"
    end
  end
end
