class DocumentSelection < ApplicationRecord
  belongs_to :grading_task
  has_one :student_submission, dependent: :nullify

  validates :document_id, presence: true
end
