# GradingResponse is the public interface returned by the GradingService
#
# It serves as a simple data transfer object containing either:
# - Successful grading results with feedback, strengths, opportunities, grade, and scores
# - Error information when grading fails
#
# This class is used as the boundary between the GradingService and its clients,
# providing a consistent interface regardless of how the grading was performed
# or what parsing strategy was used.
class GradingResponse
  attr_reader :feedback, :strengths, :opportunities, :overall_grade, :rubric_scores, :error, :summary, :question

  # Initialize a new GradingResponse
  #
  # @param attributes [Hash] The attributes for this response
  # @option attributes [String] :feedback The narrative feedback
  # @option attributes [Array] :strengths Strengths identified in the submission
  # @option attributes [Array] :opportunities Areas for improvement
  # @option attributes [String] :overall_grade The letter grade assigned
  # @option attributes [Hash] :rubric_scores Scores for different rubric criteria
  # @option attributes [String] :error Error message if grading failed
  def initialize(attributes = {})
    # Initialize with default values to avoid nil errors
    @feedback = attributes[:feedback] || ""
    @strengths = attributes[:strengths] || []
    @opportunities = attributes[:opportunities] || []
    @overall_grade = attributes[:overall_grade] || "Not graded"
    @rubric_scores = attributes[:rubric_scores] || {}
    @error = attributes[:error]
    @summary = attributes[:summary] || ""
    @question = attributes[:question] || ""
  end

  # Create a new GradingResponse with an error message
  #
  # @param message [String] The error message
  # @return [GradingResponse] A new response with the error message
  def self.error(message)
    new(error: message)
  end

  def success?
    @error.nil?
  end

  def failure?
    !success?
  end

  def to_h
    {
      feedback: @feedback,
      strengths: @strengths,
      opportunities: @opportunities,
      overall_grade: @overall_grade,
      rubric_scores: @rubric_scores,
      summary: @summary,
      question: @question
    }
  end
end
