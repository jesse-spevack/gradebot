class Level < ApplicationRecord
  belongs_to :criterion, dependent: :destroy

  validates :title, presence: true
  validates :points, presence: true
  validates :position, presence: true, uniqueness: { scope: :criterion_id }
end
