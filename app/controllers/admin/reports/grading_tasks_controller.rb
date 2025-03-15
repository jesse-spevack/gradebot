# frozen_string_literal: true

module Admin
  module Reports
    # Controller for grading task cost reports
    class GradingTasksController < BaseController
      # GET /admin/reports/grading_tasks
      def show
        # Get grading tasks with costs for the specified date range
        command = ListGradingTaskCostsCommand.new(
          start_date: @start_date.beginning_of_day,
          end_date: @end_date.end_of_day
        )
        result = command.call

        if result.success?
          @grading_task_costs = result.result
          @total_cost = @grading_task_costs.sum(&:cost)
        else
          flash.now[:alert] = "Error retrieving grading task costs: #{result.errors.join(', ')}"
          @grading_task_costs = []
          @total_cost = BigDecimal("0")
        end
      end
    end
  end
end
