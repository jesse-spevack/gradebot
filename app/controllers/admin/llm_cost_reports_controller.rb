module Admin
  class LLMCostReportsController < BaseController
    def index
      @date_range = params.fetch(:date_range, 30).to_i
      @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today - @date_range.days
      @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

      @total_cost = LlmCostLog.for_date_range(@start_date, @end_date).total_cost
      @cost_by_type = LlmCostLog.for_date_range(@start_date, @end_date).cost_breakdown_by_type
      @cost_by_model = LlmCostLog.for_date_range(@start_date, @end_date).cost_breakdown_by_model
      @daily_costs = LlmCostLog.for_date_range(@start_date, @end_date).daily_costs(@date_range)

      # Get top users by cost
      user_costs = LlmCostLog.for_date_range(@start_date, @end_date).cost_breakdown_by_user
      @top_users = user_costs.sort_by { |_, cost| -cost }.to_h
    end

    def user_costs
      @user = User.find(params[:user_id])
      @date_range = params.fetch(:date_range, 30).to_i
      @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today - @date_range.days
      @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

      @costs = LlmCostLog.for_user(@user).for_date_range(@start_date, @end_date)
      @total_cost = @costs.total_cost
      @cost_by_type = @costs.cost_breakdown_by_type
      @cost_by_model = @costs.cost_breakdown_by_model
      @daily_costs = @costs.daily_costs(@date_range)
    end
  end
end
