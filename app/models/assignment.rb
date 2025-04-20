class Assignment < ApplicationRecord
  has_prefix_id :as
  # Associations
  belongs_to :user
  has_one :rubric, dependent: :destroy
  has_many :student_works, dependent: :destroy
  has_one :assignment_summary, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :subject, presence: true
  validates :grade_level, presence: true
end
