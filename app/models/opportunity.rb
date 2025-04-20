class Opportunity < ApplicationRecord
  # Associations
  belongs_to :recordable, polymorphic: true

  # Validations
  validates :content, presence: true
  validates :reason, presence: true
end
