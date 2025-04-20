class StudentWorkCriterionLevel < ApplicationRecord
  # Prefix ID
  has_prefix_id :swcl

  # Associations
  belongs_to :student_work
  belongs_to :criterion
  belongs_to :level

  # Validations
  validates :criterion_id, uniqueness: { scope: :student_work_id, message: "has already been evaluated for this student work" }
end
