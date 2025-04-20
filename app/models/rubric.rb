class Rubric < ApplicationRecord
  has_prefix_id :rb
  # Associations
  belongs_to :assignment
  has_many :criteria, dependent: :destroy

  # Validations
  validates :title, presence: true
end
