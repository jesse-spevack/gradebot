class Feature < ApplicationRecord
  has_prefix_id :ftr

  validates :title, presence: true
  validates :description, presence: true

  has_one_attached :image

  default_scope { order(release_date: :desc) }
end
