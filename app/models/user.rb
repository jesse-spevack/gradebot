class User < ApplicationRecord
  has_many :sessions
  has_many :grading_tasks
  has_many :user_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :google_uid, presence: true, uniqueness: true

  def self.from_google_auth(auth)
    user = find_or_initialize_by(google_uid: auth["uid"])
    user.assign_attributes(
      email: auth["info"]["email"],
      name: auth["info"]["name"],
      profile_picture_url: auth["info"]["image"]
    )
    user.save!

    # Create a new token record
    if auth["credentials"].present?
      # Store token data
      user.user_tokens.create!(
        access_token: auth["credentials"]["token"],
        refresh_token: auth["credentials"]["refresh_token"],
        expires_at: Time.at(auth["credentials"]["expires_at"]),
        scopes: auth["credentials"]["scope"]
      )
    end

    user
  end

  def admin?
    admin
  end

  # Get the most recent valid Google token
  #
  # @return [UserToken, nil] the most recent valid token or nil if none exists
  def current_google_token
    UserToken.latest_for_user(self)
  end
  
  # Backward compatibility method to directly get the access token
  # @return [String, nil] the access token string or nil if no token exists
  def google_token
    token = current_google_token
    return nil unless token
    
    begin
      token_service = TokenService.new(self)
      token_service.access_token
    rescue TokenService::TokenError => e
      Rails.logger.error("Failed to get access token for user #{id}: #{e.message}")
      nil
    end
  end
end
