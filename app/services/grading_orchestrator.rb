# frozen_string_literal: true

# Service to orchestrate the grading process
class GradingOrchestrator
  # @param submission [StudentSubmission] The submission to grade
  # @param document_content [String] The content of the document to grade
  def initialize(student_submission:, document_content:)
    @student_submission = student_submission
    @document_content = document_content
    @grading_task = student_submission.grading_task
  end

  # Grades the submission using the GradingService
  # @return [GradingResponse] The grading result
  # @raise [StandardError] If an error occurs during grading
  def grade
    Rails.logger.info("Starting to grade submission #{@student_submission.id} for document #{@student_submission.original_doc_id}")

    grading_service = GradingService.new

    grading_service.grade_submission(
      @document_content,
      @grading_task.assignment_prompt,
      @grading_task.grading_rubric,
      @student_submission,  # Pass submission as trackable
      @grading_task.user # Pass the user who created the grading task
    )
  end
end
