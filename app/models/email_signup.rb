class EmailSignup < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  attr_accessor :form_id
end
