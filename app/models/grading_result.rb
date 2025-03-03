# GradingResult is a value object that represents the parsed result of an LLM grading response
#
# It contains the structured data extracted from an LLM response, including:
# - feedback: The main narrative feedback for the student
# - strengths: An array of identified strengths in the submission
# - opportunities: An array of improvement opportunities
# - overall_grade: The letter grade assigned (e.g., "A", "B+")
# - scores: A hash of scores for different rubric criteria
#
# This object also provides validation methods to check if the result is valid and complete.
# It handles normalization of data to ensure consistency regardless of the parsing strategy used.
class GradingResult
  attr_reader :feedback, :strengths, :opportunities, :overall_grade, :scores

  # Initialize a new GradingResult with the parsed data
  #
  # @param feedback [String] The narrative feedback
  # @param strengths [Array, String] Strengths identified in the submission
  # @param opportunities [Array, String] Areas for improvement
  # @param overall_grade [String] The letter grade assigned
  # @param scores [Hash] Scores for different rubric criteria
  def initialize(feedback:, strengths:, opportunities:, overall_grade:, scores:)
    @feedback = feedback || ""
    @strengths = normalize_array(strengths)
    @opportunities = normalize_array(opportunities)
    @overall_grade = overall_grade || "Not graded"
    @scores = normalize_scores(scores)
  end

  def valid?
    feedback.present? &&
    !strengths.empty? &&
    !opportunities.empty? &&
    overall_grade.present? &&
    !scores.empty?
  end

  def complete?
    valid? &&
    feedback.length > 20 &&
    strengths.size >= 2 &&
    opportunities.size >= 1 &&
    overall_grade.match?(/[A-F][+-]?/) &&
    scores.values.all? { |v| v.is_a?(Numeric) }
  end

  private

  def normalize_array(value)
    case value
    when Array then value
    when String then [ value ]
    when nil then []
    else [ value.to_s ]
    end
  end

  def normalize_scores(scores)
    return {} if scores.nil?

    case scores
    when Hash
      scores.transform_values { |v| v.is_a?(Numeric) ? v : v.to_s.scan(/\d+/).first.to_i rescue 0 }
    when String
      # Try to parse scores from string
      result = {}
      scores.scan(/([A-Za-z\s]+):\s*(\d+)/) do |category, score|
        result[category.strip] = score.to_i
      end
      result
    else
      {}
    end
  end
end
