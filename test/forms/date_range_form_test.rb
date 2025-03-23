require "test_helper"

class DateRangeFormTest < ActiveSupport::TestCase
  test "initializes with default values when params are empty" do
    # Setup
    form = DateRangeForm.new({})

    # Verify
    assert_equal "range_preset", form.filter_type
    assert_equal 7, form.date_range
    assert_nil form.start_date
    assert_nil form.end_date
  end

  test "initializes with provided params" do
    # Setup
    params = {
      filter_type: "specific_dates",
      start_date: "2025-01-01",
      end_date: "2025-01-31",
      date_range: "30"
    }
    form = DateRangeForm.new(params)

    # Verify
    assert_equal "specific_dates", form.filter_type
    assert_equal "2025-01-01", form.start_date
    assert_equal "2025-01-31", form.end_date
    assert_equal "30", form.date_range
  end

  test "calculates dates from range" do
    # Setup
    form = DateRangeForm.new(filter_type: "range_preset", date_range: "30")

    # Exercise
    form.calculate_dates_from_range

    # Verify
    assert_not_nil form.start_date
    assert_not_nil form.end_date

    start_date = Date.parse(form.start_date)
    end_date = Date.parse(form.end_date)

    assert_equal 30, (end_date - start_date).to_i
    assert_equal Date.today, end_date
  end

  test "specific_dates_selected? returns true when filter_type is specific_dates" do
    # Setup
    form = DateRangeForm.new(filter_type: "specific_dates")

    # Verify
    assert form.specific_dates_selected?
  end

  test "specific_dates_selected? returns false when filter_type is not specific_dates" do
    # Setup
    form = DateRangeForm.new(filter_type: "range_preset")

    # Verify
    assert_not form.specific_dates_selected?
  end
end
