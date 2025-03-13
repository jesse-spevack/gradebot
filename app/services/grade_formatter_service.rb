# frozen_string_literal: true

# Service to format grading results for storage
class GradeFormatterService
  # @param grading_result [GradingResponse] The grading result to format
  # @param document_content [String] The content of the document that was graded
  # @param submission [StudentSubmission] The submission that was graded
  def initialize(grading_result, document_content, submission)
    @result = grading_result
    @document_content = document_content
    @submission = submission
  end

  # Formats the grading result for storage in the database
  # @return [Hash] A hash of attributes for updating the submission
  def format_for_storage
    {
      feedback: @result.feedback,
      strengths: format_array_attribute(@result.strengths),
      opportunities: format_array_attribute(@result.opportunities),
      overall_grade: @result.overall_grade,
      rubric_scores: @result.rubric_scores.to_json,
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
    existing_metadata = @submission.metadata || {}

    {
      doc_title: @submission.document_title || "Untitled Document",
      processing_time: (Time.current - @submission.updated_at).round(1),
      word_count: @document_content.split(/\s+/).size,
      summary: @result.summary,
      question: @result.question
    }.merge(existing_metadata)
  end
end
