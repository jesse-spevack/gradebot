class Criterion < ApplicationRecord
  # Add prefix ID according to conventions
  has_prefix_id :crit

  # Associations
  belongs_to :rubric
  has_many :levels, dependent: :destroy

  # Validations
  validates :title, presence: true
end
