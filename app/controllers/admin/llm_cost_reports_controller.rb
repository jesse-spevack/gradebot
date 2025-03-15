# frozen_string_literal: true

class Admin::LLMCostReportsController < Admin::BaseController
  def daily_costs
    redirect_to admin_reports_daily_path(start_date: params[:start_date], end_date: params[:end_date])
  end

  def grading_task_costs
    redirect_to admin_reports_grading_tasks_path(start_date: params[:start_date], end_date: params[:end_date])
  end
end
