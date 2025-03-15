# frozen_string_literal: true

module Admin
  module Reports
    # Base controller for all admin reports
    # Provides shared functionality like date range handling
    class BaseController < Admin::BaseController
      before_action :set_date_range, only: [ :show ]

      private

      # Sets the date range for reports based on parameters
      # If no parameters are provided, defaults to the last 7 days
      def set_date_range
        @date_range = params[:date_range]&.to_i || 7

        # Handle quick date range selection
        if params[:date_range].present? && !params[:start_date].present? && !params[:end_date].present?
          days = @date_range
          @end_date = Date.today
          @start_date = @end_date - days.days
        elsif params[:start_date].present? && params[:end_date].present?
          # Use explicitly provided dates
          @start_date = Date.parse(params[:start_date])
          @end_date = Date.parse(params[:end_date])
        else
          # Default to last 7 days if no dates are provided
          @end_date = Date.today
          @start_date = @end_date - 7.days
        end
      end
    end
  end
end
