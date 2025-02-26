# frozen_string_literal: true

require "test_helper"

class FeatureFlagTest < ActiveSupport::TestCase
  test "validates presence of key" do
    feature_flag = FeatureFlag.new(name: "Test Flag")
    assert_not feature_flag.valid?
    assert_includes feature_flag.errors[:key], "can't be blank"
  end

  test "validates uniqueness of key" do
    FeatureFlag.create!(key: "test_key", name: "Test Flag")
    duplicate = FeatureFlag.new(key: "test_key", name: "Another Flag")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "validates presence of name" do
    feature_flag = FeatureFlag.new(key: "test_key")
    assert_not feature_flag.valid?
    assert_includes feature_flag.errors[:name], "can't be blank"
  end

  test "sets last_changed_at when enabled state changes" do
    freeze_time do
      feature_flag = FeatureFlag.create!(key: "test_key", name: "Test Flag", enabled: false)
      original_time = feature_flag.last_changed_at

      travel 1.day

      feature_flag.update!(enabled: true)
      assert_not_equal original_time, feature_flag.reload.last_changed_at
      assert_equal Time.current, feature_flag.last_changed_at
    end
  end

  test "does not update last_changed_at when other attributes change" do
    feature_flag = FeatureFlag.create!(key: "test_key", name: "Test Flag", enabled: false)
    original_time = feature_flag.last_changed_at

    travel 1.day

    feature_flag.update!(name: "Updated Flag Name")
    assert_equal original_time, feature_flag.reload.last_changed_at
  end

  test "provides scope for finding enabled flags" do
    FeatureFlag.create!(key: "enabled_flag", name: "Enabled Flag", enabled: true)
    FeatureFlag.create!(key: "disabled_flag", name: "Disabled Flag", enabled: false)

    enabled_flags = FeatureFlag.enabled

    assert_equal 1, enabled_flags.count
    assert_equal "enabled_flag", enabled_flags.first.key
  end

  test "provides enabled? class method to check if a feature is enabled" do
    FeatureFlag.create!(key: "active_feature", name: "Active Feature", enabled: true)
    FeatureFlag.create!(key: "inactive_feature", name: "Inactive Feature", enabled: false)

    assert FeatureFlag.enabled?("active_feature")
    assert_not FeatureFlag.enabled?("inactive_feature")
    assert_not FeatureFlag.enabled?("nonexistent_feature")
  end

  test "provides scope for finding disabled flags" do
    FeatureFlag.create!(key: "enabled_flag", name: "Enabled Flag", enabled: true)
    FeatureFlag.create!(key: "disabled_flag", name: "Disabled Flag", enabled: false)

    disabled_flags = FeatureFlag.disabled

    assert_equal 1, disabled_flags.count
    assert_equal "disabled_flag", disabled_flags.first.key
  end

  test "provides scope for finding recently changed flags" do
    freeze_time do
      old_flag = FeatureFlag.create!(key: "old_flag", name: "Old Flag", enabled: true)
      old_flag.update_column(:last_changed_at, 10.days.ago)

      FeatureFlag.create!(key: "recent_flag", name: "Recent Flag", enabled: true)

      assert_equal 1, FeatureFlag.recently_changed.count
      assert_equal "recent_flag", FeatureFlag.recently_changed.first.key
    end
  end

  test "provides scope for ordering flags by name" do
    FeatureFlag.create!(key: "b_flag", name: "B Flag")
    FeatureFlag.create!(key: "a_flag", name: "A Flag")
    FeatureFlag.create!(key: "c_flag", name: "C Flag")

    ordered_flags = FeatureFlag.ordered_by_name

    assert_equal 3, ordered_flags.count
    assert_equal %w[A\ Flag B\ Flag C\ Flag].map { |s| s.gsub("\\", "") }, ordered_flags.map(&:name)
  end
end
