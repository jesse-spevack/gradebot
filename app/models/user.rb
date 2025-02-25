class User < ApplicationRecord
  has_many :sessions
  has_many :grading_tasks

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :google_uid, presence: true, uniqueness: true

  def self.from_google_auth(auth)
    user = find_or_initialize_by(google_uid: auth["uid"])
    user.assign_attributes(
      email: auth["info"]["email"],
      name: auth["info"]["name"],
      profile_picture_url: auth["info"]["image"],
      access_token: auth["credentials"]["token"],
      refresh_token: auth["credentials"]["refresh_token"],
      token_expires_at: Time.at(auth["credentials"]["expires_at"])
    )
    user.save!
    user
  end

  def token_expired?
    token_expires_at.nil? || token_expires_at < Time.current
  end

  def google_token
    return nil if token_expired?
    access_token
  end
end
