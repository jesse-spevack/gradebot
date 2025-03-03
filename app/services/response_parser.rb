# frozen_string_literal: true

# Parses LLM responses into structured data
class ResponseParser
  def self.parse(response)
    return GradingResponse.new(error: "No response to parse") if response.blank?

    # Try parsing as JSON first
    begin
      result = JSON.parse(response)
      return GradingResponse.new(
        feedback: result["feedback"],
        strengths: result["strengths"],
        opportunities: result["opportunities"],
        overall_grade: result["overall_grade"],
        rubric_scores: result["scores"]
      ) if valid_response?(result)
    rescue JSON::ParserError
      # Continue to other strategies if JSON parsing fails
    end

    # Try other parsing strategies
    strategies.each do |strategy|
      begin
        result = strategy.parse(response)
        return result if result&.success?
      rescue => e
        last_error = e
      end
    end

    raise last_error || ParsingError.new("Failed to parse response using any strategy")
  end

  private

  def self.valid_response?(result)
    result.is_a?(Hash) &&
      result["feedback"].present? &&
      result["strengths"].is_a?(Array) &&
      result["opportunities"].is_a?(Array)
  end

  def self.strategies
    [
      Strategies::FixedJsonStrategy.new,
      Strategies::RegexPatternStrategy.new,
      Strategies::StructuredTextStrategy.new
    ]
  end
end
