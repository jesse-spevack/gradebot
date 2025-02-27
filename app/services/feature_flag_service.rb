# frozen_string_literal: true

# Service for managing feature flags and tracking changes
#
# This service provides methods for checking, enabling, and disabling feature flags.
# It includes caching for better performance and audit logging for all changes.
#
# @example Check if a feature is enabled
#   service = FeatureFlagService.new
#   if service.enabled?("new_feature")
#     # Do something when feature is enabled
#   end
#
# @example Enable a feature flag
#   service = FeatureFlagService.new
#   service.enable("new_feature", current_user)
#
# @example Disable a feature flag
#   service = FeatureFlagService.new
#   service.disable("new_feature", current_user)
class FeatureFlagService
  # Cache key prefix for feature flags
  CACHE_KEY_PREFIX = "feature_flag:".freeze

  # Default cache expiration time in seconds (1 hour)
  DEFAULT_CACHE_EXPIRATION = 1.hour

  # Check if a feature is enabled by its key
  #
  # @param key [String] the feature flag key
  # @param force_refresh [Boolean] whether to bypass the cache and check the database directly
  # @return [Boolean] true if the feature is enabled, false otherwise
  def enabled?(key, force_refresh: false)
    key = key.to_s
    cache_key = cache_key_for(key)

    if force_refresh
      update_cache(key)
    else
      # Try to get from cache first
      cached_value = Rails.cache.read(cache_key)
      return cached_value unless cached_value.nil?

      # If not in cache, get from database and cache it
      update_cache(key)
    end
  end

  # Enable a feature flag
  #
  # @param key [String] the feature flag key
  # @param user [User] the user performing the action
  # @return [Boolean] true if the flag was enabled, false if it doesn't exist
  def enable(key, user)
    set_enabled(key, true, user)
  end

  # Disable a feature flag
  #
  # @param key [String] the feature flag key
  # @param user [User] the user performing the action
  # @return [Boolean] true if the flag was disabled, false if it doesn't exist
  def disable(key, user)
    set_enabled(key, false, user)
  end

  # Set the enabled status of a feature flag
  #
  # @param key [String] the feature flag key
  # @param enabled [Boolean] the new enabled state
  # @param user [User] the user performing the action
  # @return [Boolean] true if the operation was successful, false otherwise
  def set_enabled(key, enabled, user)
    key = key.to_s
    flag = find_flag(key)
    return false unless flag

    # Skip if the status is already what we want
    return true if flag.enabled == enabled

    # Store previous state for audit log
    previous_state = flag.enabled

    # Update the flag and create audit log in a transaction
    FeatureFlag.transaction do
      flag.update!(enabled: enabled)
      create_audit_log(flag, user, enabled ? "enabled" : "disabled", previous_state, enabled)
    end

    # Update the cache
    update_cache(key, enabled)

    true
  end

  # Refresh all cached flags from the database
  #
  # @return [Boolean] true if the refresh was successful
  def refresh_all_cache
    FeatureFlag.find_each do |flag|
      update_cache(flag.key, flag.enabled)
    end
    true
  end

  # Get all features flags with their current status
  #
  # @param force_refresh [Boolean] whether to bypass the cache
  # @return [Hash{String => Boolean}] hash of feature keys and their statuses
  def all_flags(force_refresh: false)
    if force_refresh
      flags = {}
      FeatureFlag.find_each do |flag|
        flags[flag.key] = flag.enabled
        update_cache(flag.key, flag.enabled)
      end
      flags
    else
      # Try to use cached values where available
      result = {}
      FeatureFlag.select(:id, :key, :enabled).find_each do |flag|
        cache_key = cache_key_for(flag.key)
        cached_value = Rails.cache.read(cache_key)
        
        if cached_value.nil?
          # Not in cache, add it
          update_cache(flag.key, flag.enabled)
          result[flag.key] = flag.enabled
        else
          # Use cached value
          result[flag.key] = cached_value
        end
      end
      result
    end
  end

  private

  # Find a feature flag by key
  #
  # @param key [String] the feature flag key
  # @return [FeatureFlag, nil] the feature flag or nil if not found
  def find_flag(key)
    FeatureFlag.find_by(key: key)
  end

  # Create an audit log entry for a feature flag change
  #
  # @param flag [FeatureFlag] the feature flag
  # @param user [User] the user who made the change
  # @param action [String] the action performed (enabled/disabled)
  # @param previous_state [Boolean] the previous enabled state
  # @param new_state [Boolean] the new enabled state
  # @return [FeatureFlagAuditLog] the created audit log
  def create_audit_log(flag, user, action, previous_state, new_state)
    FeatureFlagAuditLog.create!(
      feature_flag: flag,
      user: user,
      action: action,
      previous_state: previous_state,
      new_state: new_state
    )
  end

  # Generate a cache key for a feature flag
  #
  # @param key [String] the feature flag key
  # @return [String] the cache key
  def cache_key_for(key)
    "#{CACHE_KEY_PREFIX}#{key}"
  end

  # Update the cache for a feature flag
  #
  # @param key [String] the feature flag key
  # @param value [Boolean, nil] the value to cache, or nil to fetch from database
  # @return [Boolean] the cached value
  def update_cache(key, value = nil)
    cache_key = cache_key_for(key)
    
    # If value not provided, get it from the database
    unless value.nil?
      Rails.cache.write(cache_key, value, expires_in: DEFAULT_CACHE_EXPIRATION)
      return value
    end

    # Get from database and cache
    enabled = FeatureFlag.enabled?(key)
    Rails.cache.write(cache_key, enabled, expires_in: DEFAULT_CACHE_EXPIRATION)
    enabled
  end
end
