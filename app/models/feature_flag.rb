# frozen_string_literal: true

# Represents a feature flag that can be toggled on/off to control feature availability
class FeatureFlag < ApplicationRecord
  # Associations
  has_many :audit_logs, class_name: "FeatureFlagAuditLog", dependent: :destroy

  # Validations
  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :recently_changed, ->(days = 7) { where("last_changed_at >= ?", days.days.ago) }
  scope :ordered_by_name, -> { order(:name) }

  # Class methods
  # Check if a feature is enabled by its key
  # @param key [String] the feature flag key
  # @return [Boolean] true if the feature is enabled, false otherwise
  def self.enabled?(key)
    enabled.exists?(key: key.to_s)
  end

  # Callbacks
  before_save :update_last_changed_at, if: :will_save_change_to_enabled?

  private

  # Updates the last_changed_at timestamp when the enabled state changes
  def update_last_changed_at
    self.last_changed_at = Time.current
  end
end
