# frozen_string_literal: true

# Service for managing feature flags and tracking changes
class FeatureFlagService
  # Check if a feature is enabled by its key
  # @param key [String] the feature flag key
  # @return [Boolean] true if the feature is enabled, false otherwise
  def enabled?(key)
    FeatureFlag.enabled?(key.to_s)
  end

  # Enable a feature flag
  # @param key [String] the feature flag key
  # @param user [User] the user performing the action
  # @return [Boolean] true if the flag was enabled, false if it doesn't exist
  def enable(key, user)
    flag = FeatureFlag.find_by(key: key.to_s)
    return false unless flag

    # Skip if already enabled
    return true if flag.enabled?

    previous_state = flag.enabled
    flag.update!(enabled: true)

    # Create audit log
    FeatureFlagAuditLog.create!(
      feature_flag: flag,
      user: user,
      action: "enabled",
      previous_state: previous_state,
      new_state: true
    )

    true
  end

  # Disable a feature flag
  # @param key [String] the feature flag key
  # @param user [User] the user performing the action
  # @return [Boolean] true if the flag was disabled, false if it doesn't exist
  def disable(key, user)
    flag = FeatureFlag.find_by(key: key.to_s)
    return false unless flag

    # Skip if already disabled
    return true if !flag.enabled?

    previous_state = flag.enabled
    flag.update!(enabled: false)

    # Create audit log
    FeatureFlagAuditLog.create!(
      feature_flag: flag,
      user: user,
      action: "disabled",
      previous_state: previous_state,
      new_state: false
    )

    true
  end
end 