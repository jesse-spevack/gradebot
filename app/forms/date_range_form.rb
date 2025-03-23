class DateRangeForm
  include ActiveModel::Model

  attr_accessor :filter_type, :start_date, :end_date, :date_range

  def initialize(params = {})
    @filter_type = params[:filter_type] || "range_preset"
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @date_range = params[:date_range] || 7
  end

  def specific_dates_selected?
    filter_type == "specific_dates"
  end

  def range_preset_selected?
    !specific_dates_selected?
  end

  def calculate_dates_from_range
    return unless date_range.present?

    days = date_range.to_i
    end_date_obj = Date.today
    start_date_obj = end_date_obj - days

    @end_date = end_date_obj.strftime("%Y-%m-%d")
    @start_date = start_date_obj.strftime("%Y-%m-%d")
  end

  def formatted_start_date
    start_date
  end

  def formatted_end_date
    end_date
  end

  def to_params
    {
      filter_type: filter_type,
      start_date: start_date,
      end_date: end_date,
      date_range: date_range
    }
  end
end
