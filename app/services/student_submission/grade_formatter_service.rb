# frozen_string_literal: true

# Service to format grading results for storage
class StudentSubmission::GradeFormatterService
  # @param grading_response [GradingResponse] The grading result to format
  # @param document_content [String] The content of the document that was graded
  # @param student_submission [StudentSubmission] The submission that was graded
  def initialize(grading_response:, document_content:, student_submission:)
    @grading_response = grading_response
    @document_content = document_content
    @student_submission = student_submission
  end

  # Formats the grading result for storage in the database
  # @return [Hash] A hash of attributes for updating the submission
  def format_for_storage
    {
      feedback: @grading_response.feedback,
      strengths: format_array_attribute(@grading_response.strengths),
      opportunities: format_array_attribute(@grading_response.opportunities),
      overall_grade: @grading_response.overall_grade,
      rubric_scores: @grading_response.rubric_scores.to_json,
      metadata: build_metadata
    }
  end

  private

  # Formats array attributes (strengths, opportunities) into a consistent format
  # @param attribute [Array, String] The attribute to format
  # @return [String] The formatted attribute
  def format_array_attribute(attribute)
    case attribute
    when Array
      attribute.empty? ? "" : "- " + attribute.join("\n- ")
    when String
      attribute
    else
      attribute.to_s
    end
  end

  # Builds metadata for the submission
  # @return [Hash] The metadata
  def build_metadata
    existing_metadata = @student_submission.metadata || {}

    {
      doc_title: @student_submission.document_title || "Untitled Document",
      processing_time: (Time.current - @student_submission.updated_at).round(1),
      word_count: @document_content.split(/\s+/).size,
      summary: @grading_response.summary,
      question: @grading_response.question
    }.merge(existing_metadata)
  end
end
