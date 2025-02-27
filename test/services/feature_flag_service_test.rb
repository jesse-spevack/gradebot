# frozen_string_literal: true

require "test_helper"

class FeatureFlagServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @service = FeatureFlagService.new
    # Clear the cache before each test
    Rails.cache.clear
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

  test "uses caching for feature flags" do
    # Skip this test if caching is not enabled or is a NullStore
    skip "Caching not properly configured for testing" if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)

    flag = FeatureFlag.create!(key: "cached_flag", name: "Cached Flag", enabled: true)
    
    # Verify the service works normally
    assert @service.enabled?("cached_flag")
    
    # Now directly update the database without going through the service
    flag.update_column(:enabled, false)
    
    # Without force_refresh, should return the cached value
    assert @service.enabled?("cached_flag")
    
    # With force_refresh, should return the current value
    assert_not @service.enabled?("cached_flag", force_refresh: true)
  end

  test "updates cache when flag is enabled" do
    flag = FeatureFlag.create!(key: "test_update_cache", name: "Test Update Cache", enabled: false)
    
    # Initial check will cache the disabled state
    assert_not @service.enabled?("test_update_cache")
    
    # Enable the flag through the service
    @service.enable("test_update_cache", @user)
    
    # Service should return the updated cached value
    assert @service.enabled?("test_update_cache")
  end

  test "updates cache when flag is disabled" do
    flag = FeatureFlag.create!(key: "test_update_cache", name: "Test Update Cache", enabled: true)
    
    # Initial check will cache the enabled state
    assert @service.enabled?("test_update_cache")
    
    # Disable the flag through the service
    @service.disable("test_update_cache", @user)
    
    # Service should return the updated cached value
    assert_not @service.enabled?("test_update_cache")
  end

  test "can force refresh flag from database" do
    flag = FeatureFlag.create!(key: "refresh_flag", name: "Refresh Flag", enabled: true)
    
    # Initial check will cache the enabled state
    assert @service.enabled?("refresh_flag")
    
    # Manually change the flag status in the database
    flag.update_column(:enabled, false)
    
    # Force refresh should bypass cache and get the current state
    assert_not @service.enabled?("refresh_flag", force_refresh: true)
  end

  test "can set enabled status to a specific value" do
    flag = FeatureFlag.create!(key: "test_set_flag", name: "Test Set Flag", enabled: false)
    
    # Set to true
    @service.set_enabled("test_set_flag", true, @user)
    assert flag.reload.enabled?
    
    # Set to false
    @service.set_enabled("test_set_flag", false, @user)
    assert_not flag.reload.enabled?
    
    # Setting to current value should not create a log entry
    assert_no_difference "FeatureFlagAuditLog.count" do
      @service.set_enabled("test_set_flag", false, @user)
    end
  end
end
