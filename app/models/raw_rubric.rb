class RawRubric < ApplicationRecord
  belongs_to :grading_task
  belongs_to :rubric, optional: true

  validates :content, presence: true,
                     length: { maximum: 10_000, message: "cannot be longer than 10,000 characters" }
  validates :rubric, presence: { message: "must be provided" }
  validate :rubric_must_be_persisted

  private

  def rubric_must_be_persisted
    return unless rubric.present?

    errors.add(:rubric, "must be saved before creating a raw rubric") unless rubric.persisted?
  end
end
