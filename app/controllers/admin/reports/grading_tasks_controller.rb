# frozen_string_literal: true

module Admin
  module Reports
    class GradingTasksController < BaseController
      def show
        command = GetGradingTaskCostsCommand.call(
          start_date: @start_date.beginning_of_day,
          end_date: @end_date.end_of_day
        )

        if command.success?
          @grading_task_costs = command.result
          @total_cost = @grading_task_costs.sum(&:cost)
        else
          flash.now[:alert] = "Error retrieving grading task costs: #{command.errors.join(', ')}"
          @grading_task_costs = []
          @total_cost = BigDecimal("0")
        end
      end
    end
  end
end
