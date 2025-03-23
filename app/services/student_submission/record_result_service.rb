# frozen_string_literal: true

class StudentSubmission::RecordResultService
  attr_reader :student_submission, :grading_response, :document_content

  class << self
    def record(student_submission:, grading_response:, document_content:)
      new(
        student_submission: student_submission,
        grading_response: grading_response,
        document_content: document_content
      ).record
    end
  end

  def initialize(student_submission:, grading_response:, document_content:)
    @student_submission = student_submission
    @grading_response = grading_response
    @document_content = document_content
  end

  def record
    StudentSubmission::StatusUpdater.transition_student_submission_to_completed(
      student_submission,
      formatter.format_for_storage
    )
  end

  def formatter
    StudentSubmission::GradeFormatterService.new(
      grading_response: grading_response,
      document_content: document_content,
      student_submission: student_submission
    )
  end
end
