# frozen_string_literal: true

# Tracks changes to feature flags, including who made the change and what was changed
class FeatureFlagAuditLog < ApplicationRecord
  has_prefix_id :ffal

  # Associations
  belongs_to :feature_flag
  belongs_to :user

  # Validations
  validates :action, presence: true, inclusion: { in: %w[enabled disabled] }
  validates :previous_state, inclusion: { in: [ true, false ] }
  validates :new_state, inclusion: { in: [ true, false ] }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_flag, ->(flag_id) { where(feature_flag_id: flag_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
end
