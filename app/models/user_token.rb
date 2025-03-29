# frozen_string_literal: true

# Stores OAuth tokens for users to access Google APIs in background jobs
#
# This model stores the OAuth tokens required to access Google Drive
# on behalf of a user. It includes methods to check if tokens have
# expired and need refreshing.
class UserToken < ApplicationRecord
  has_prefix_id :utok
  # Associations
  belongs_to :user

  # Validations
  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true

  # Scopes
  scope :for_user, ->(user) { where(user: user) }
  scope :latest_first, -> { order(created_at: :desc) }

  # Buffer time (in seconds) to consider a token as "expiring soon"
  EXPIRY_BUFFER = 5.minutes

  # Check if the token has expired
  #
  # @return [Boolean] true if the token has expired, false otherwise
  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  # Check if the token will expire soon (within the buffer time)
  #
  # @return [Boolean] true if the token will expire soon, false otherwise
  def will_expire_soon?
    expires_at.present? && expires_at <= Time.current + EXPIRY_BUFFER
  end

  # Alias for backward compatibility
  alias_method :expires_soon?, :will_expire_soon?

  # Get the most recent token for a user
  #
  # @param user [User] the user to find tokens for
  # @return [UserToken, nil] the most recent token or nil if none exists
  def self.most_recent_for(user)
    for_user(user).latest_first.first
  end

  # Alias for backward compatibility
  class << self
    alias_method :latest_for_user, :most_recent_for
  end
end
