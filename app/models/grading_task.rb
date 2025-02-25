class GradingTask < ApplicationRecord
  belongs_to :user

  validates :assignment_prompt, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :grading_rubric, presence: true, length: { minimum: 10, maximum: 3000 }
  validates :folder_id, presence: true
  validates :folder_name, presence: true
end
