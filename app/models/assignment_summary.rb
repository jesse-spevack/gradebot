class AssignmentSummary < ApplicationRecord
  # Prefix ID
  has_prefix_id :asum_

  # Associations
  belongs_to :assignment
  has_many :feedback_items, as: :feedbackable, dependent: :destroy

  # Validations
  validates :assignment, presence: true
  validates :student_work_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :qualitative_insights, presence: true
end
