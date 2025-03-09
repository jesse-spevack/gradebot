module Admin
  class LLMCostReportsController < BaseController
    before_action :set_date_range, only: [ :index, :user_costs ]

    def index
      if @start_date.present? && @end_date.present?
        # Get all LLM cost logs within the specified date range
        @logs = LLMCostLog.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)

        # Calculate total cost for the period
        @total_cost = @logs.sum(:cost)

        # Calculate total tokens
        @total_prompt_tokens = @logs.sum(:prompt_tokens)
        @total_completion_tokens = @logs.sum(:completion_tokens)
        @total_tokens = @total_prompt_tokens + @total_completion_tokens

        # Get top model by cost
        model_costs = @logs.group(:llm_model_name).sum(:cost)
        @top_model = model_costs.max_by { |k, v| v } if model_costs.present?

        # Get top request type by cost
        type_costs = @logs.group(:request_type).sum(:cost)
        @top_type = type_costs.max_by { |k, v| v } if type_costs.present?

        # Get cost per day for the chart - using standard Rails methods instead of group_by_day
        @daily_costs = @logs.group("DATE(created_at)").sum(:cost)
        # Convert date strings to Date objects for better formatting in views
        @daily_costs = @daily_costs.transform_keys { |k| k.is_a?(String) ? Date.parse(k) : k }

        # Get top users by cost
        @top_users = @logs.joins(:user).group("users.email").sum(:cost).sort_by { |_, v| -v }.take(5)

        # Get top models and request types for pie charts
        @cost_by_model = model_costs.sort_by { |_, v| -v }.take(5).to_h
        @cost_by_type = type_costs.sort_by { |_, v| -v }.take(5).to_h
      else
        # Initialize empty data if no date range provided
        @total_cost = 0
        @total_prompt_tokens = 0
        @total_completion_tokens = 0
        @total_tokens = 0
        @top_model = nil
        @top_type = nil
        @daily_costs = {}
        @top_users = []
        @cost_by_model = {}
        @cost_by_type = {}
      end
    end

    def user_costs
      @all_users = User.order(:email)
      @user = params[:user_id].present? ? User.find(params[:user_id]) : nil

      if @start_date.present? && @end_date.present?
        # Base query for logs in the date range
        @logs_query = LLMCostLog.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)

        # Filter by user if specified
        @logs_query = @logs_query.where(user: @user) if @user.present?

        # Calculate totals
        @total_cost = @logs_query.sum(:cost)
        @total_prompt_tokens = @logs_query.sum(:prompt_tokens)
        @total_completion_tokens = @logs_query.sum(:completion_tokens)
        @total_tokens = @total_prompt_tokens + @total_completion_tokens

        # Get model breakdown
        @cost_by_model = @logs_query.group(:llm_model_name).sum(:cost).sort_by { |_, v| -v }.to_h
        @top_model = @cost_by_model.first if @cost_by_model.present?

        # Get request type breakdown
        @cost_by_type = @logs_query.group(:request_type).sum(:cost).sort_by { |_, v| -v }.to_h
        @top_type = @cost_by_type.first if @cost_by_type.present?

        # Get daily costs for chart - using standard Rails methods instead of group_by_day
        @daily_costs = @logs_query.group("DATE(created_at)").sum(:cost)
        # Convert date strings to Date objects for better formatting in views
        @daily_costs = @daily_costs.transform_keys { |k| k.is_a?(String) ? Date.parse(k) : k }

        # Get recent activity
        @costs = @logs_query.order(created_at: :desc)
      else
        # Initialize empty data if no date range provided
        @total_cost = 0
        @total_prompt_tokens = 0
        @total_completion_tokens = 0
        @total_tokens = 0
        @cost_by_model = {}
        @top_model = nil
        @cost_by_type = {}
        @top_type = nil
        @daily_costs = {}
        @costs = LLMCostLog.none
      end
    end

    private

    def set_date_range
      @date_range = params[:date_range]&.to_i || 30

      # Only set dates if explicitly provided by the user
      @start_date = Date.parse(params[:start_date]) if params[:start_date].present?
      @end_date = Date.parse(params[:end_date]) if params[:end_date].present?
    end
  end
end
