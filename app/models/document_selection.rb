# frozen_string_literal: true

class DocumentSelection < ApplicationRecord
  has_prefix_id :ds

  belongs_to :grading_task
  has_one :student_submission, dependent: :nullify

  validates :document_id, presence: true
end
