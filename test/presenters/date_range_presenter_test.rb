require 'test_helper'

class DateRangePresenterTest < ActiveSupport::TestCase
  test "initializes with a form object" do
    # Setup
    form = DateRangeForm.new
    
    # Exercise
    presenter = DateRangePresenter.new(form)
    
    # Verify
    assert_equal form, presenter.form
  end
  
  test "specific_dates_section_hidden? is true when range preset is selected" do
    # Setup
    form = DateRangeForm.new(filter_type: "range_preset")
    presenter = DateRangePresenter.new(form)
    
    # Verify
    assert presenter.specific_dates_section_hidden?
  end
  
  test "specific_dates_section_hidden? is false when specific dates is selected" do
    # Setup
    form = DateRangeForm.new(filter_type: "specific_dates")
    presenter = DateRangePresenter.new(form)
    
    # Verify
    assert_not presenter.specific_dates_section_hidden?
  end
  
  test "range_preset_section_hidden? is true when specific dates is selected" do
    # Setup
    form = DateRangeForm.new(filter_type: "specific_dates")
    presenter = DateRangePresenter.new(form)
    
    # Verify
    assert presenter.range_preset_section_hidden?
  end
  
  test "range_preset_section_hidden? is false when range preset is selected" do
    # Setup
    form = DateRangeForm.new(filter_type: "range_preset")
    presenter = DateRangePresenter.new(form)
    
    # Verify
    assert_not presenter.range_preset_section_hidden?
  end
  
  test "formatted_start_date returns formatted date" do
    # Setup
    form = DateRangeForm.new(start_date: "2025-03-22")
    presenter = DateRangePresenter.new(form)
    
    # Verify
    assert_equal "2025-03-22", presenter.formatted_start_date
  end
  
  test "formatted_end_date returns formatted date" do
    # Setup
    form = DateRangeForm.new(end_date: "2025-03-22")
    presenter = DateRangePresenter.new(form)
    
    # Verify
    assert_equal "2025-03-22", presenter.formatted_end_date
  end
end
