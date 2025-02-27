# frozen_string_literal: true

require "test_helper"

class FeatureFlagAuditLogTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @feature_flag = FeatureFlag.create!(key: "test_flag", name: "Test Flag")
  end

  test "validates required fields" do
    audit_log = FeatureFlagAuditLog.new
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:feature_flag], "must exist"
    assert_includes audit_log.errors[:user], "must exist"
    assert_includes audit_log.errors[:action], "can't be blank"
  end

  test "validates action value" do
    audit_log = FeatureFlagAuditLog.new(
      feature_flag: @feature_flag,
      user: @user,
      previous_state: false,
      new_state: true
    )

    # Invalid action
    audit_log.action = "invalid_action"
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:action], "is not included in the list"

    # Valid actions
    audit_log.action = "enabled"
    assert audit_log.valid?

    audit_log.action = "disabled"
    assert audit_log.valid?
  end

  test "creates a valid audit log" do
    audit_log = FeatureFlagAuditLog.new(
      feature_flag: @feature_flag,
      user: @user,
      action: "enabled",
      previous_state: false,
      new_state: true
    )

    assert audit_log.valid?
    assert audit_log.save
  end

  test "scopes work correctly" do
    # Create some audit logs
    log1 = FeatureFlagAuditLog.create!(
      feature_flag: @feature_flag,
      user: @user,
      action: "enabled",
      previous_state: false,
      new_state: true,
      created_at: 2.days.ago
    )

    log2 = FeatureFlagAuditLog.create!(
      feature_flag: @feature_flag,
      user: users(:teacher2),
      action: "disabled",
      previous_state: true,
      new_state: false,
      created_at: 1.day.ago
    )

    # Test recent scope
    recent_logs = FeatureFlagAuditLog.recent
    assert_equal log2.id, recent_logs.first.id
    assert_equal log1.id, recent_logs.last.id

    # Test by_flag scope
    flag_logs = FeatureFlagAuditLog.by_flag(@feature_flag.id)
    assert_equal 2, flag_logs.count

    # Test by_user scope
    user_logs = FeatureFlagAuditLog.by_user(@user.id)
    assert_equal 1, user_logs.count
    assert_equal log1.id, user_logs.first.id
  end
end 