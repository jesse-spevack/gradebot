module Strategies
  # JsonStrategy attempts direct JSON parsing for well-formed responses
  #
  # This is the most reliable strategy when the LLM responds with properly formatted JSON.
  # It's tried first because it's the most straightforward and accurate when successful.
  class JsonStrategy
    def parse(response)
      # Try direct JSON parsing first
      json = JSON.parse(response)

      # Create a GradingResponse from the parsed JSON
      GradingResponse.new(
        feedback: json["feedback"],
        strengths: json["strengths"],
        opportunities: json["opportunities"],
        overall_grade: json["overall_grade"],
        rubric_scores: json["scores"]
      )
    end
  end
end
