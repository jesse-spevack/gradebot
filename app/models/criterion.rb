class Criterion < ApplicationRecord
  belongs_to :rubric
  has_many :levels, -> { order(position: :asc) }, dependent: :destroy

  validates :title, presence: true
  validates :points, presence: true
  validates :position, presence: true, uniqueness: { scope: :rubric_id }
end
