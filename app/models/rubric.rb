class Rubric < ApplicationRecord
  # Associations
  belongs_to :assignment
  has_many :criteria, dependent: :destroy

  # Validations
  validates :title, presence: true
end
