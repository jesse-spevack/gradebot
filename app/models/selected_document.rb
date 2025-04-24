class SelectedDocument < ApplicationRecord
  # Prefix ID
  has_prefix_id :sd

  # Associations
  belongs_to :assignment

  # Validations
  validates :assignment, presence: true
  validates :google_doc_id, presence: true
  validates :url, presence: true
  validates :title, presence: true
end
