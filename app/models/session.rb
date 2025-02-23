class Session < ApplicationRecord
  belongs_to :user

  validates :user, presence: true
  validates :user_agent, presence: true
  validates :ip_address, presence: true

  def self.authenticate(user:, user_agent:, ip_address:)
    create!(user: user, user_agent: user_agent, ip_address: ip_address)
  end
end
