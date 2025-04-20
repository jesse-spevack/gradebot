# frozen_string_literal: true

class GetGradingTaskCostsCommand < CommandBase
  private

  def execute
    if start_date > end_date
      @errors << "Invalid date range: start date must be before end date"
      return nil
    end

    @grading_tasks = find_grading_tasks
    return [] if @grading_tasks.empty?

    calculate_costs_for_tasks
  end

  def find_grading_tasks
    query = GradingTask.all
    query = query.where("created_at >= ?", start_date) if start_date
    query = query.where("created_at <= ?", end_date) if end_date
    query.order(created_at: :desc)
  end

  def calculate_costs_for_tasks
    student_submissions = StudentSubmission.where(grading_task: @grading_tasks)
    submissions_by_task = student_submissions.group_by(&:grading_task_id)

    costs = get_costs_for_trackables(
      grading_tasks: @grading_tasks,
      student_submissions: student_submissions
    )

    @grading_tasks.map do |task|
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

  def get_costs_for_trackables(grading_tasks:, student_submissions:)
    # Build conditions for the query
    conditions = []

    # Add grading tasks to conditions
    unless grading_tasks.empty?
      conditions << LLMCostLog.where(
        trackable_type: "GradingTask",
        trackable_id: grading_tasks.pluck(:id)
      )
    end

    # Add submissions to conditions
    unless student_submissions.empty?
      conditions << LLMCostLog.where(
        trackable_type: "StudentSubmission",
        trackable_id: student_submissions.pluck(:id)
      )
    end

    # Combine conditions with OR
    query = conditions.reduce { |combined, condition| combined.or(condition) }

    # Apply date filters if provided
    query = query.where("created_at >= ?", start_date)
    query = query.where("created_at <= ?", end_date)

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

  def start_date
    @start_date ||= GradingTask.minimum(:created_at) || 1.year.ago
  end

  def end_date
    @end_date ||= Time.now
  end
end
