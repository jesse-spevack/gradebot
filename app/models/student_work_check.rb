class StudentWorkCheck < ApplicationRecord
  # Prefix ID
  has_prefix_id :chk

  # Associations
  belongs_to :student_work

  # Enum for check type
  enum :check_type, { llm_generated: 0, writing_grade_level: 1, plagiarism: 2 }

  # Validations
  validates :student_work, presence: true
  validates :check_type, presence: true
  validates :score, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  # Custom validation for score range based on check_type
  validate :score_range_for_writing_grade_level

  private

  def score_range_for_writing_grade_level
    # Only apply this validation if the check_type is writing_grade_level and score is present
    return unless writing_grade_level? && score.present?

    unless score.between?(1, 12)
      errors.add(:score, "must be between 1 and 12 for writing grade level check type")
    end
  end
end
