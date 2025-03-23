# frozen_string_literal: true

module Admin
  module Reports
    # Base controller for all admin reports
    # Provides shared functionality like date range handling
    class BaseController < Admin::BaseController
      before_action :set_date_range, only: [ :show ]

      # Make @date_form available to views
      helper_method :date_form

      # Public accessor for the date form to be used in views
      def date_form
        @date_form
      end

      private

      # Sets the date range for reports using DateRangeForm
      # Encapsulates the date range logic in a form object for better maintainability
      def set_date_range
        @date_form = DateRangeForm.new(params)

        # Handle form processing based on filter type
        if @date_form.range_preset_selected?
          @date_form.calculate_dates_from_range
        end

        # Set instance variables for controller and views
        @date_range = @date_form.date_range.to_i

        # Parse the dates from form fields
        if @date_form.start_date.present? && @date_form.end_date.present?
          @start_date = Date.parse(@date_form.start_date)
          @end_date = Date.parse(@date_form.end_date)
        else
          # Fallback to defaults if something went wrong
          @end_date = Date.today
          @start_date = @end_date - 7.days

          # Update the form with the default dates
          @date_form.start_date = @start_date.strftime("%Y-%m-%d")
          @date_form.end_date = @end_date.strftime("%Y-%m-%d")
        end
      end
    end
  end
end
