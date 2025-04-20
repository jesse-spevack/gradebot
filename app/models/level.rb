class Level < ApplicationRecord
  # Prefix ID
  has_prefix_id :lvl

  # Associations
  belongs_to :criterion

  # Validations
  validates :title, presence: true
end
