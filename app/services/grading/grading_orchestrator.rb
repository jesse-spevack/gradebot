# frozen_string_literal: true

class Grading::GradingOrchestrator
  class << self
    def grade(student_submission:, document_content:)
      new(student_submission: student_submission, document_content: document_content).grade
    end
  end

  def initialize(student_submission:, document_content:)
    @student_submission = student_submission
    @document_content = document_content
    @grading_task = student_submission.grading_task
  end

  def grade
    Rails.logger.info("Starting to grade submission #{@student_submission.id} for document #{@student_submission.original_doc_id}")

    grading_service = Grading::GradingService.new

    grading_service.grade_submission(
      @document_content,
      @grading_task.assignment_prompt,
      @grading_task.grading_rubric,
      @student_submission,
      @grading_task.user
    )
  end
end
