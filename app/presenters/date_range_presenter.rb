class DateRangePresenter
  attr_reader :form
  
  def initialize(form)
    @form = form || DateRangeForm.new
  end
  
  def specific_dates_selected?
    form.specific_dates_selected?
  end
  
  def range_preset_selected?
    form.range_preset_selected?
  end
  
  def specific_dates_section_hidden?
    range_preset_selected?
  end
  
  def range_preset_section_hidden?
    specific_dates_selected?
  end
  
  def formatted_start_date
    form.start_date
  end
  
  def formatted_end_date
    form.end_date
  end
  
  def date_range_options
    [
      ["Last 7 days", 7],
      ["Last 30 days", 30],
      ["Last 90 days", 90],
      ["Last 365 days", 365]
    ]
  end
  
  def default_range
    form.date_range || 7
  end
  
  def form_data_attributes
    {
      controller: "date-range-toggle date-range",
      date_range_target: "form"
    }
  end
  
  def specific_dates_radio_attributes
    {
      checked: specific_dates_selected?,
      class: "h-4 w-4 text-blue-600 border-gray-300",
      data: { action: "click->date-range-toggle#showSpecificDates" }
    }
  end
  
  def range_preset_radio_attributes
    {
      checked: range_preset_selected?,
      class: "h-4 w-4 text-blue-600 border-gray-300",
      data: { action: "click->date-range-toggle#showRangePreset" }
    }
  end
end
