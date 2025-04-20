class RubricCriterionScore < ApplicationRecord
  # Associations
  belongs_to :student_submission
  belongs_to :criterion
  belongs_to :level

  # Validations
  validates :points_earned, presence: true
  validates :reason, presence: true
  validates :evidence, presence: true
  validate :points_earned_within_criterion_limit

  delegate :rubric, to: :grading_task
  delegate :grading_task, to: :student_submission

  private

  def points_earned_within_criterion_limit
    return unless criterion && points_earned.present? && criterion.points.present?

    if points_earned > criterion.points
      errors.add(:points_earned, "cannot exceed criterion points")
    end
  end
end
