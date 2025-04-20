class StudentSubmissionCheck < ApplicationRecord
  # Associations
  belongs_to :student_submission

  # Enums
  enum :check_type, { plagiarism: 0, authenticity: 1 }

  # Validations
  validates :check_type, presence: true
  validates :score, presence: true
  validates :reason, presence: true
end
