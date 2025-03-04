require "test_helper"

class LlmCostLogTest < ActiveSupport::TestCase
  def test_validations
    # Model name must be present
    log = LlmCostLog.new(cost: 0.01)
    refute log.valid?
    assert_includes log.errors.full_messages, "LLM model name can't be blank"

    # Cost must be non-negative
    log = LlmCostLog.new(llm_model_name: "claude-3-sonnet", cost: -1)
    refute log.valid?
    assert_includes log.errors.full_messages, "Cost must be greater than or equal to 0"

    # Valid log
    log = LlmCostLog.new(llm_model_name: "claude-3-sonnet", cost: 0.01)
    assert log.valid?
  end

  def test_associations
    # User is optional
    log = LlmCostLog.new(llm_model_name: "claude-3-sonnet", cost: 0.01)
    assert log.valid?

    # Can be associated with a user
    user = users(:teacher)
    log.user = user
    assert log.valid?
    assert_equal user, log.user

    # Trackable is optional
    log = LlmCostLog.new(llm_model_name: "claude-3-sonnet", cost: 0.01)
    assert log.valid?

    # Can be associated with a trackable
    submission = student_submissions(:pending_submission)
    log.trackable = submission
    assert log.valid?
    assert_equal submission, log.trackable
  end

  def setup_log_data
    # Clear existing data
    LlmCostLog.delete_all

    user1 = users(:teacher)
    user2 = users(:teacher2)
    submission = student_submissions(:pending_submission)

    # Create logs with specific timestamps for date range testing
    # Day 1
    LlmCostLog.create!(
      user: user1,
      request_type: "grading",
      llm_model_name: "claude-3-sonnet",
      cost: 0.01,
      created_at: 1.day.ago.beginning_of_day
    )

    # Day 2
    LlmCostLog.create!(
      user: user1,
      request_type: "feedback",
      llm_model_name: "claude-3-haiku",
      cost: 0.02,
      created_at: 2.days.ago.beginning_of_day
    )

    # Day 3
    LlmCostLog.create!(
      user: user2,
      request_type: "grading",
      llm_model_name: "claude-3-sonnet",
      cost: 0.03,
      created_at: 3.days.ago.beginning_of_day
    )

    # Day 4
    LlmCostLog.create!(
      user: user2,
      request_type: "summary",
      llm_model_name: "claude-3-opus",
      cost: 0.04,
      trackable: submission,
      created_at: 4.days.ago.beginning_of_day
    )
  end

  def test_scope_for_user
    setup_log_data

    user = users(:teacher)
    logs = LlmCostLog.for_user(user)

    assert_equal 2, logs.count
    logs.each do |log|
      assert_equal user, log.user
    end
  end

  def test_scope_for_request_type
    setup_log_data

    logs = LlmCostLog.for_request_type("grading")

    assert_equal 2, logs.count
    logs.each do |log|
      assert_equal "grading", log.request_type
    end
  end

  def test_scope_for_model
    setup_log_data

    logs = LlmCostLog.for_model("claude-3-sonnet")

    assert_equal 2, logs.count
    logs.each do |log|
      assert_equal "claude-3-sonnet", log.llm_model_name
    end
  end

  def test_scope_for_date_range
    setup_log_data

    # Use a wider date range to ensure we capture all records
    start_date = 4.days.ago.beginning_of_day
    end_date = Time.current.end_of_day

    logs = LlmCostLog.for_date_range(start_date, end_date)

    # We should get all 4 records
    assert_equal 4, logs.count

    # Now test a narrower range
    start_date = 3.days.ago.beginning_of_day
    end_date = 1.day.ago.end_of_day

    logs = LlmCostLog.for_date_range(start_date, end_date)

    # We should get 3 records (days 1, 2, and 3)
    assert_equal 3, logs.count
  end

  def test_scope_for_trackable
    setup_log_data

    trackable = student_submissions(:pending_submission)
    logs = LlmCostLog.for_trackable(trackable)

    assert_equal 1, logs.count
    assert_equal trackable, logs.first.trackable
  end

  def setup_reporting_data
    # Clear existing data
    LlmCostLog.delete_all

    user1 = users(:teacher)
    user2 = users(:teacher2)

    # Create logs with specific timestamps for daily costs testing
    LlmCostLog.create!(
      user: user1,
      request_type: "grading",
      llm_model_name: "claude-3-sonnet",
      cost: 0.01,
      created_at: 1.day.ago.beginning_of_day
    )

    LlmCostLog.create!(
      user: user1,
      request_type: "feedback",
      llm_model_name: "claude-3-haiku",
      cost: 0.02,
      created_at: 2.days.ago.beginning_of_day
    )

    LlmCostLog.create!(
      user: user2,
      request_type: "grading",
      llm_model_name: "claude-3-sonnet",
      cost: 0.03,
      created_at: 3.days.ago.beginning_of_day
    )

    LlmCostLog.create!(
      user: user2,
      request_type: "summary",
      llm_model_name: "claude-3-opus",
      cost: 0.04,
      created_at: 4.days.ago.beginning_of_day
    )
  end

  def test_total_cost
    setup_reporting_data

    assert_equal 0.1, LlmCostLog.total_cost
  end

  def test_cost_breakdown_by_type
    setup_reporting_data

    breakdown = LlmCostLog.cost_breakdown_by_type
    assert_equal 0.04, breakdown["grading"]
    assert_equal 0.02, breakdown["feedback"]
    assert_equal 0.04, breakdown["summary"]
  end

  def test_cost_breakdown_by_model
    setup_reporting_data

    breakdown = LlmCostLog.cost_breakdown_by_model
    assert_equal 0.04, breakdown["claude-3-sonnet"]
    assert_equal 0.02, breakdown["claude-3-haiku"]
    assert_equal 0.04, breakdown["claude-3-opus"]
  end

  def test_cost_breakdown_by_user
    setup_reporting_data

    breakdown = LlmCostLog.cost_breakdown_by_user
    # We need to know the email addresses of the fixture users
    user1_email = users(:teacher).email
    user2_email = users(:teacher2).email

    assert_equal 0.03, breakdown[user1_email]
    assert_equal 0.07, breakdown[user2_email]
  end

  def test_daily_costs
    setup_reporting_data

    daily = LlmCostLog.daily_costs(7)
    assert_equal 4, daily.keys.count
    assert_in_delta 0.1, daily.values.sum, 0.001
  end

  def test_daily_costs_respects_days_parameter
    # Clear existing data and set up a clean test
    LlmCostLog.delete_all

    user = users(:teacher)

    # Create exactly 3 days of data
    LlmCostLog.create!(
      user: user,
      request_type: "grading",
      llm_model_name: "claude-3-sonnet",
      cost: 0.01,
      created_at: Time.current.beginning_of_day
    )

    LlmCostLog.create!(
      user: user,
      request_type: "feedback",
      llm_model_name: "claude-3-haiku",
      cost: 0.02,
      created_at: 1.day.ago.beginning_of_day
    )

    LlmCostLog.create!(
      user: user,
      request_type: "summary",
      llm_model_name: "claude-3-opus",
      cost: 0.03,
      created_at: 2.days.ago.beginning_of_day
    )

    # Test that we only get 2 days when limit is 2
    daily = LlmCostLog.daily_costs(2)

    assert_equal 2, daily.keys.size
  end

  def test_generate_report
    # Setup
    setup_reporting_data
    today = Date.today
    five_days_ago = today - 5.days

    # Exercise - test by day
    day_report = LlmCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :day
    )

    # Verify
    assert_equal 4, day_report.keys.size

    # Exercise - test by user
    user_report = LlmCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :user
    )

    # Verify
    teacher_id = users(:teacher).id
    teacher2_id = users(:teacher2).id
    assert_in_delta 0.03, user_report[teacher_id], 0.001
    assert_in_delta 0.07, user_report[teacher2_id], 0.001

    # Exercise - test by model
    model_report = LlmCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :model
    )

    # Verify
    assert_in_delta 0.04, model_report["claude-3-sonnet"], 0.001
    assert_in_delta 0.02, model_report["claude-3-haiku"], 0.001
    assert_in_delta 0.04, model_report["claude-3-opus"], 0.001

    # Exercise - test by request type
    type_report = LlmCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :request_type
    )

    # Verify
    assert_in_delta 0.04, type_report["grading"], 0.001
    assert_in_delta 0.02, type_report["feedback"], 0.001
    assert_in_delta 0.04, type_report["summary"], 0.001

    # Exercise - test total
    total_report = LlmCostLog.generate_report(
      start_date: five_days_ago,
      end_date: today,
      group_by: :invalid
    )

    # Verify
    assert_in_delta 0.1, total_report[:total], 0.001
  end
end
