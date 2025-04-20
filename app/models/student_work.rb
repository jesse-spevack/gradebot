class StudentWork < ApplicationRecord
  # Prefix ID
  has_prefix_id :sw

  # Associations
  belongs_to :assignment
  has_many :feedback_items, dependent: :destroy
  has_many :student_work_checks, dependent: :destroy

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  # Validations
  validates :assignment, presence: true
end
