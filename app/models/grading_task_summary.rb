class GradingTaskSummary < ApplicationRecord
  # Associations
  belongs_to :grading_task
  has_many :strengths, as: :recordable, dependent: :destroy
  has_many :opportunities, as: :recordable, dependent: :destroy

  # Enums
  enum :status, { pending: 0, processing: 1, completed: 2 }

  # Validations
  validates :insights, presence: true
  validates :status, presence: true
end
