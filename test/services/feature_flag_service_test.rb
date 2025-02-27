# frozen_string_literal: true

require "test_helper"

class FeatureFlagServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @service = FeatureFlagService.new
  end

  test "returns false for non-existent flags" do
    assert_not @service.enabled?("non_existent_flag")
  end

  test "returns the enabled state for existing flags" do
    # Create a disabled flag
    disabled_flag = FeatureFlag.create!(key: "disabled_test_flag", name: "Disabled Test Flag", enabled: false)
    assert_not @service.enabled?("disabled_test_flag")

    # Create an enabled flag
    enabled_flag = FeatureFlag.create!(key: "enabled_test_flag", name: "Enabled Test Flag", enabled: true)
    assert @service.enabled?("enabled_test_flag")
  end

  test "can enable flags and records who made the change" do
    flag = FeatureFlag.create!(key: "test_flag", name: "Test Flag", enabled: false)

    assert_difference "FeatureFlagAuditLog.count", 1 do
      @service.enable("test_flag", @user)
    end

    assert flag.reload.enabled?

    audit_log = FeatureFlagAuditLog.last
    assert_equal flag.id, audit_log.feature_flag_id
    assert_equal @user.id, audit_log.user_id
    assert_equal "enabled", audit_log.action
    assert_equal false, audit_log.previous_state
    assert_equal true, audit_log.new_state
  end

  test "can disable flags and records who made the change" do
    flag = FeatureFlag.create!(key: "test_flag", name: "Test Flag", enabled: true)

    assert_difference "FeatureFlagAuditLog.count", 1 do
      @service.disable("test_flag", @user)
    end

    assert_not flag.reload.enabled?

    audit_log = FeatureFlagAuditLog.last
    assert_equal flag.id, audit_log.feature_flag_id
    assert_equal @user.id, audit_log.user_id
    assert_equal "disabled", audit_log.action
    assert_equal true, audit_log.previous_state
    assert_equal false, audit_log.new_state
  end

  test "returns false when trying to enable a non-existent flag" do
    assert_no_difference "FeatureFlagAuditLog.count" do
      result = @service.enable("non_existent_flag", @user)
      assert_not result
    end
  end

  test "returns false when trying to disable a non-existent flag" do
    assert_no_difference "FeatureFlagAuditLog.count" do
      result = @service.disable("non_existent_flag", @user)
      assert_not result
    end
  end
end
