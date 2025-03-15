# frozen_string_literal: true

module Admin
  module Reports
    # Controller for daily LLM cost reports
    class DailyController < BaseController
      # GET /admin/reports/daily
      def show
        # Get all LLM cost logs within the specified date range
        @logs = LLMCostLog.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)

        # Calculate total cost for the period
        @total_cost = @logs.sum(:cost)

        # Get cost per day for the chart using Groupdate
        @daily_costs = @logs.group_by_day(:created_at, range: @start_date.beginning_of_day..@end_date.end_of_day).sum(:cost)

        # Fill in any missing days with zero values
        # This ensures a continuous date range for the chart
        (@start_date..@end_date).each do |date|
          @daily_costs[date.to_time] ||= 0
        end
      end
    end
  end
end
