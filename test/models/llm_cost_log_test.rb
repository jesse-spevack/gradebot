require "test_helper"

class LLMCostLogTest < ActiveSupport::TestCase
  def test_validations
    # Model name must be present
    log = LLMCostLog.new(cost: 0.01)
    assert_not log.valid?
    assert_includes log.errors[:llm_model_name], "can't be blank"

    # Cost must be non-negative
    log = LLMCostLog.new(llm_model_name: "claude-3-5-sonnet", cost: -1)
    assert_not log.valid?
    assert_includes log.errors[:cost], "must be greater than or equal to 0"

    # Valid with required fields
    log = LLMCostLog.new(llm_model_name: "claude-3-5-sonnet", cost: 0.01)
    assert log.valid?
  end

  def test_associations
    # User is optional
    log = LLMCostLog.new(llm_model_name: "claude-3-5-sonnet", cost: 0.01)
    assert log.valid?

    # Trackable is optional
    log = LLMCostLog.new(llm_model_name: "claude-3-5-sonnet", cost: 0.01)
    assert log.valid?

    # Can be associated with a user
    user = users(:teacher)
    log.user = user
    assert log.valid?
    assert_equal user, log.user

    # Trackable is optional
    submission = student_submissions(:pending_submission)
    log.trackable = submission
    assert log.valid?
    assert_equal submission, log.trackable
  end

  def setup_log_data
    # Clear existing data
    LLMCostLog.delete_all

    user1 = users(:teacher)
    user2 = users(:teacher2)

    # Create logs with varying models, users, types
    LLMCostLog.create!(
      user: user1,
      request_type: "grading",
      llm_model_name: "claude-3-5-sonnet",
      cost: 0.02,
      prompt_tokens: 100,
      completion_tokens: 300,
      total_tokens: 400,
      created_at: 1.day.ago
    )

    LLMCostLog.create!(
      user: user1,
      request_type: "feedback",
      llm_model_name: "claude-3-5-haiku",
      cost: 0.01,
      prompt_tokens: 80,
      completion_tokens: 200,
      total_tokens: 280,
      created_at: 2.days.ago
    )

    LLMCostLog.create!(
      user: user2,
      request_type: "grading",
      llm_model_name: "claude-3-5-sonnet",
      cost: 0.02,
      prompt_tokens: 120,
      completion_tokens: 350,
      total_tokens: 470,
      created_at: 3.days.ago
    )

    # One entry with a trackable
    LLMCostLog.create!(
      user: user2,
      request_type: "summary",
      llm_model_name: "claude-3-5-haiku",
      cost: 0.01,
      prompt_tokens: 90,
      completion_tokens: 210,
      total_tokens: 300,
      trackable: student_submissions(:pending_submission),
      created_at: 4.days.ago
    )
  end

  def test_scope_for_user
    setup_log_data

    user = users(:teacher)
    logs = LLMCostLog.for_user(user)

    assert_equal 2, logs.count
    logs.each do |log|
      assert_equal user, log.user
    end
  end

  def test_scope_for_request_type
    setup_log_data

    logs = LLMCostLog.for_request_type("grading")

    assert_equal 2, logs.count
    logs.each do |log|
      assert_equal "grading", log.request_type
    end
  end

  def test_scope_for_model
    setup_log_data

    # Test filtering by model
    logs = LLMCostLog.for_model("claude-3-5-sonnet")
    assert_equal 2, logs.count

    log = logs.first
    assert_equal "claude-3-5-sonnet", log.llm_model_name
  end

  def test_scope_for_date_range
    setup_log_data

    # Use a wider date range to ensure we capture all records
    start_date = 4.days.ago.beginning_of_day
    end_date = Time.current.end_of_day

    logs = LLMCostLog.for_date_range(start_date, end_date)

    # We should get all 4 records
    assert_equal 4, logs.count

    # Now test a narrower range
    start_date = 3.days.ago.beginning_of_day
    end_date = 1.day.ago.end_of_day

    logs = LLMCostLog.for_date_range(start_date, end_date)

    # We should get 3 records (days 1, 2, and 3)
    assert_equal 3, logs.count
  end

  def test_scope_for_trackable
    setup_log_data

    trackable = student_submissions(:pending_submission)
    logs = LLMCostLog.for_trackable(trackable)

    assert_equal 1, logs.count
    assert_equal trackable, logs.first.trackable
  end

  def setup_reporting_data
    # Clear existing data
    LLMCostLog.delete_all

    user1 = users(:teacher)
    user2 = users(:teacher2)

    # Create logs with specific timestamps for daily costs testing
    LLMCostLog.create!(
      user: user1,
      request_type: "grading",
      llm_model_name: "claude-3-5-sonnet",
      cost: 0.01,
      created_at: 1.day.ago.beginning_of_day
    )

    LLMCostLog.create!(
      user: user1,
      request_type: "feedback",
      llm_model_name: "claude-3-5-haiku",
      cost: 0.02,
      created_at: 2.days.ago.beginning_of_day
    )

    LLMCostLog.create!(
      user: user2,
      request_type: "grading",
      llm_model_name: "claude-3-5-sonnet",
      cost: 0.03,
      created_at: 3.days.ago.beginning_of_day
    )

    LLMCostLog.create!(
      user: user2,
      request_type: "summary",
      llm_model_name: "claude-3-5-haiku",
      cost: 0.04,
      created_at: 4.days.ago.beginning_of_day
    )
  end

  def test_total_cost
    setup_reporting_data

    assert_in_delta 0.1, LLMCostLog.total_cost, 0.001
  end

  def test_cost_breakdown_by_type
    setup_reporting_data

    breakdown = LLMCostLog.cost_breakdown_by_type
    assert_in_delta 0.04, breakdown["grading"], 0.001
    assert_in_delta 0.02, breakdown["feedback"], 0.001
    assert_in_delta 0.04, breakdown["summary"], 0.001
  end

  def test_cost_breakdown_by_model
    setup_reporting_data

    # Test model breakdown
    breakdown = LLMCostLog.cost_breakdown_by_model

    assert_in_delta 0.04, breakdown["claude-3-5-sonnet"], 0.001
    assert_in_delta 0.06, breakdown["claude-3-5-haiku"], 0.001
  end

  def test_cost_breakdown_by_user
    setup_reporting_data

    breakdown = LLMCostLog.cost_breakdown_by_user
    # We need to know the email addresses of the fixture users
    user1_email = users(:teacher).email
    user2_email = users(:teacher2).email

    assert_in_delta 0.03, breakdown[user1_email], 0.001
    assert_in_delta 0.07, breakdown[user2_email], 0.001
  end

  def test_daily_costs
    setup_reporting_data

    daily = LLMCostLog.daily_costs(7)
    assert_equal 4, daily.keys.count

    # Use the model's built-in method for cents conversion
    daily_cents = LLMCostLog.daily_costs_in_cents(7)
    expected_cents = 10 # 0.1 dollars = 10 cents
    # Debug logging
    Rails.logger.debug "Daily cents sum: #{daily_cents.values.sum}"
    # Use a small delta for floating-point comparisons
    assert_in_delta expected_cents, daily_cents.values.sum, 1
  end

  def test_daily_costs_respects_days_parameter
    # Clear existing data and set up a clean test
    LLMCostLog.delete_all

    # Create entries with specific dates
    entry1 = LLMCostLog.create!(
      llm_model_name: "claude-3-5-sonnet",
      cost: 0.01,
      created_at: 1.day.ago
    )

    entry2 = LLMCostLog.create!(
      llm_model_name: "claude-3-5-haiku",
      cost: 0.02,
      created_at: 8.days.ago
    )

    entry3 = LLMCostLog.create!(
      llm_model_name: "claude-3-5-sonnet",
      cost: 0.03,
      created_at: 15.days.ago
    )

    # Test with 7-day window (should only include entry1)
    daily7 = LLMCostLog.daily_costs(7)
    assert_equal 1, daily7.keys.size

    # Test with 10-day window (should include entry1 and entry2)
    daily10 = LLMCostLog.daily_costs(10)
    assert_equal 2, daily10.keys.size

    # Test with 20-day window (should include all entries)
    daily20 = LLMCostLog.daily_costs(20)
    assert_equal 3, daily20.keys.size
  end

  def test_generate_report
    # Start with a clean slate
    LLMCostLog.delete_all

    # Create test users
    user1 = users(:teacher)
    user2 = users(:teacher2)

    # Define our test data structure so we can derive expected values
    test_data = [
      { user: user1, request_type: "grading", model: "claude-3-5-sonnet", cost: 0.01, days_ago: 1 },
      { user: user1, request_type: "feedback", model: "claude-3-5-haiku", cost: 0.02, days_ago: 2 },
      { user: user2, request_type: "grading", model: "claude-3-5-sonnet", cost: 0.03, days_ago: 3 },
      { user: user2, request_type: "summary", model: "claude-3-5-haiku", cost: 0.04, days_ago: 4 }
    ]

    # Create the log entries
    test_data.each do |data|
      LLMCostLog.create!(
        user: data[:user],
        request_type: data[:request_type],
        llm_model_name: data[:model],
        cost: data[:cost],
        created_at: data[:days_ago].days.ago.beginning_of_day
      )
    end

    # Calculate expected totals
    expected_total = test_data.sum { |d| d[:cost] }
    # Convert to cents for precise comparison
    expected_total_cents = (expected_total * 100).round

    # Inspect the actual values for debugging
    Rails.logger.debug "Expected total: #{expected_total}, expected cents: #{expected_total_cents}"

    # Calculate expected breakdowns
    expected_by_user = {
      user1.email => test_data.select { |d| d[:user] == user1 }.sum { |d| d[:cost] },
      user2.email => test_data.select { |d| d[:user] == user2 }.sum { |d| d[:cost] }
    }

    expected_by_model = test_data.group_by { |d| d[:model] }
                               .transform_values { |items| items.sum { |d| d[:cost] } }

    expected_by_type = test_data.group_by { |d| d[:request_type] }
                              .transform_values { |items| items.sum { |d| d[:cost] } }

    # Clear time-related data for predictable results
    today = Date.today
    five_days_ago = today - 5.days

    # 1. Test daily report
    day_report = LLMCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :day,
      in_cents: true
    )

    assert day_report.is_a?(Hash)
    # Debug logging to see the actual values
    Rails.logger.debug "Day report values: #{day_report.inspect}"
    Rails.logger.debug "Day report sum: #{day_report.values.sum}"

    # Use a small delta for floating-point comparisons
    assert_in_delta expected_total_cents, day_report.values.sum, 1

    # 2. Test user report
    user_report = LLMCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :user,
      in_cents: true
    )

    assert user_report.is_a?(Hash)
    # Debug logging
    Rails.logger.debug "User report sum: #{user_report.values.sum}"
    # Use a small delta for floating-point comparisons
    assert_in_delta expected_total_cents, user_report.values.sum, 1

    # Verify individual user totals (sample check)
    user1_email = user1.email
    if user_report.key?(user1_email)
      expected_user1_cents = (expected_by_user[user1_email] * 100).round
      assert_in_delta expected_user1_cents, user_report[user1_email], 1
    end

    # 3. Test model report
    model_report = LLMCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :model,
      in_cents: true
    )

    assert model_report.is_a?(Hash)
    # Debug logging
    Rails.logger.debug "Model report sum: #{model_report.values.sum}"
    # Use a small delta for floating-point comparisons
    assert_in_delta expected_total_cents, model_report.values.sum, 1

    # Verify individual model totals
    expected_by_model.each do |model, expected_cost|
      if model_report.key?(model)
        expected_model_cents = (expected_cost * 100).round
        assert_in_delta expected_model_cents, model_report[model], 1
      end
    end

    # 4. Test request type report
    type_report = LLMCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :request_type,
      in_cents: true
    )

    assert type_report.is_a?(Hash)
    # Debug logging
    Rails.logger.debug "Type report sum: #{type_report.values.sum}"
    # Use a small delta for floating-point comparisons
    assert_in_delta expected_total_cents, type_report.values.sum, 1

    # Verify individual type totals
    expected_by_type.each do |type, expected_cost|
      if type_report.key?(type)
        expected_type_cents = (expected_cost * 100).round
        assert_in_delta expected_type_cents, type_report[type], 1
      end
    end

    # 5. Test total (no grouping)
    total_report = LLMCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      in_cents: true
    )

    assert_equal 1, total_report.keys.size
    # Debug logging
    Rails.logger.debug "Total report value: #{total_report['total']}"
    # Use a small delta for floating-point comparisons
    assert_in_delta expected_total_cents, total_report["total"], 1
  end

  test "to_cents converts cost to integer cents" do
    # Test with zero
    log = LLMCostLog.new(cost: 0)
    assert_equal 0, log.to_cents

    # Test with small amount (less than a cent)
    log = LLMCostLog.new(cost: 0.00523)
    assert_equal 1, log.to_cents  # Should round to 1 cent

    # Test with typical amount
    log = LLMCostLog.new(cost: 0.0324)
    assert_equal 3, log.to_cents

    # Test with dollar amount
    log = LLMCostLog.new(cost: 1.5)
    assert_equal 150, log.to_cents

    # Test with larger amount
    log = LLMCostLog.new(cost: 23.45)
    assert_equal 2345, log.to_cents
  end

  test "to_dollars formats cost as dollar string with 4 decimal places" do
    # Test with zero
    log = LLMCostLog.new(cost: 0)
    assert_equal "$0.0000", log.to_dollars

    # Test with small amount
    log = LLMCostLog.new(cost: 0.005)
    assert_equal "$0.0050", log.to_dollars

    # Test with typical amount
    log = LLMCostLog.new(cost: 0.0324)
    assert_equal "$0.0324", log.to_dollars

    # Test with dollar amount
    log = LLMCostLog.new(cost: 1.5)
    assert_equal "$1.5000", log.to_dollars

    # Test with larger amount
    log = LLMCostLog.new(cost: 23.45)
    assert_equal "$23.4500", log.to_dollars
  end
end
