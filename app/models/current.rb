class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true

  def self.refresh_google_token
    return nil unless session&.access_token

    # If token is still valid (not expired), return it
    return session.access_token if session.token_valid?

    # Otherwise, refresh the token
    session.refresh_google_token!
    session.access_token
  rescue => e
    Rails.logger.error("Failed to refresh Google token: #{e.message}")
    nil
  end
end
