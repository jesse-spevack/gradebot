module Admin
  class LLMCostReportsController < BaseController
    before_action :set_date_range, only: [ :daily_costs ]

    def daily_costs
      # Default to last 30 days if no date range is provided
      @start_date ||= 30.days.ago.to_date
      @end_date ||= Date.today

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

    private

    def set_date_range
      @date_range = params[:date_range]&.to_i || 30

      # Handle quick date range selection
      if params[:date_range].present? && !params[:start_date].present? && !params[:end_date].present?
        days = @date_range
        @end_date = Date.today
        @start_date = @end_date - days.days
      else
        # Only set dates if explicitly provided by the user
        @start_date = Date.parse(params[:start_date]) if params[:start_date].present?
        @end_date = Date.parse(params[:end_date]) if params[:end_date].present?
      end
    end
  end
end
