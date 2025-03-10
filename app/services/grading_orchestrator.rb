# frozen_string_literal: true

# Service to orchestrate the grading process
class GradingOrchestrator
  # @param submission [StudentSubmission] The submission to grade
  # @param document_content [String] The content of the document to grade
  def initialize(submission:, document_content:)
    @submission = submission
    @document_content = document_content
    @grading_task = submission.grading_task
  end

  # Grades the submission using the GradingService
  # @return [GradingResponse] The grading result
  # @raise [StandardError] If an error occurs during grading
  def grade
    Rails.logger.info("Starting to grade submission #{@submission.id} for document #{@submission.original_doc_id}")

    grading_service = GradingService.new

    result = grading_service.grade_submission(
      @document_content,
      @grading_task.assignment_prompt,
      @grading_task.grading_rubric,
      @submission,  # Pass submission as trackable
      @grading_task.user # Pass the user who created the grading task
    )

    # Log debugging information about the result
    log_grading_result(result)

    # Handle potential errors
    handle_grading_result(result)
  end

  private

  # Logs debugging information about the grading result
  # @param result [GradingResponse] The grading result
  def log_grading_result(result)
    Rails.logger.debug("GradingOrchestrator: Received result from GradingService")
    Rails.logger.debug("GradingOrchestrator: Result error: #{result.error.inspect}")
    Rails.logger.debug("GradingOrchestrator: Result feedback: #{result.feedback&.truncate(100)}")
    Rails.logger.debug("GradingOrchestrator: Result strengths: #{result.strengths.inspect}")
    Rails.logger.debug("GradingOrchestrator: Result opportunities: #{result.opportunities.inspect}")
    Rails.logger.debug("GradingOrchestrator: Result overall_grade: #{result.overall_grade.inspect}")
    Rails.logger.debug("GradingOrchestrator: Result rubric_scores: #{result.rubric_scores.inspect}")
  end

  # Handles potential errors in the grading result
  # @param result [GradingResponse] The grading result
  # @return [GradingResponse] The grading result
  # @raise [StandardError] If the result contains an error
  def handle_grading_result(result)
    if result.error.present?
      Rails.logger.error("Grading error: #{result.error}")
      raise StandardError, "Failed to grade submission: #{result.error}"
    end

    Rails.logger.info("Successfully graded submission #{@submission.id} with grade: #{result.overall_grade}")
    result
  end
end
