module Strategies
  # RegexPatternStrategy uses regex patterns to extract data from unstructured text
  #
  # This strategy is used when JSON parsing fails completely. It looks for patterns
  # in the text that match expected fields like:
  # - "Feedback: ..." sections
  # - "Strengths:" followed by bullet points or lists
  # - "Opportunities:" followed by improvement suggestions
  # - Grade patterns like "Grade: A" or "Overall Grade: B+"
  # - Score sections with patterns like "Content: 35/40"
  #
  # This is a more flexible approach that can handle completely unstructured responses
  # when the LLM ignores the JSON formatting instructions.
  class RegexPatternStrategy
    def parse(response)
      # Extract each field separately using regex patterns
      feedback = extract_feedback(response)
      strengths = extract_strengths(response)
      opportunities = extract_opportunities(response)
      overall_grade = extract_grade(response)
      scores = extract_scores(response)

      GradingResponse.new(
        feedback: feedback,
        strengths: strengths,
        opportunities: opportunities,
        overall_grade: overall_grade,
        rubric_scores: scores
      )
    end

    private

    def extract_feedback(response)
      # Look for feedback section
      if match = response.match(/feedback[:\s]+(.+?)(?=(strengths|opportunities|overall|grade|scores))/im)
        match[1].strip
      else
        # Fallback: try to get the first paragraph
        paragraphs = response.split(/\n\s*\n/).map(&:strip).reject(&:empty?)
        paragraphs.first || "Feedback not found in response"
      end
    end

    def extract_strengths(response)
      strengths = []
      # Match both bullet point lists and arrays
      if section = response.match(/strengths[:\s]+(.*?)(?=(opportunities|overall|grade|scores))/im)
        section_text = section[1]
        # Look for bullet points or numbered items
        if bullets = section_text.scan(/[-*•]\s*(.+?)(?=[-*•]|\Z|\n\n)/m)
          strengths = bullets.flatten.map(&:strip)
        elsif items = section_text.scan(/\d+\.\s*(.+?)(?=\d+\.|\Z|\n\n)/m)
          strengths = items.flatten.map(&:strip)
        elsif json_array = section_text.match(/\[(.*?)\]/m)
          # Try to parse as JSON array
          array_items = json_array[1].split(",")
          strengths = array_items.map { |item| item.gsub(/["']/, "").strip }
        else
          # Fallback: split by newlines
          strengths = section_text.split(/[\n\r]+/).map(&:strip).reject(&:empty?)
        end
      end

      strengths.empty? ? [ "Strong points not specifically identified" ] : strengths
    end

    def extract_opportunities(response)
      opportunities = []
      # Similar pattern to strengths
      if section = response.match(/opportunities[:\s]+(.*?)(?=(strengths|overall|grade|scores))/im)
        section_text = section[1]
        # Look for bullet points or numbered items
        if bullets = section_text.scan(/[-*•]\s*(.+?)(?=[-*•]|\Z|\n\n)/m)
          opportunities = bullets.flatten.map(&:strip)
        elsif items = section_text.scan(/\d+\.\s*(.+?)(?=\d+\.|\Z|\n\n)/m)
          opportunities = items.flatten.map(&:strip)
        elsif json_array = section_text.match(/\[(.*?)\]/m)
          # Try to parse as JSON array
          array_items = json_array[1].split(",")
          opportunities = array_items.map { |item| item.gsub(/["']/, "").strip }
        else
          # Fallback: split by newlines
          opportunities = section_text.split(/[\n\r]+/).map(&:strip).reject(&:empty?)
        end
      end

      opportunities.empty? ? [ "Areas for improvement not specifically identified" ] : opportunities
    end

    def extract_grade(response)
      # Try to match different grade formats
      if match = response.match(/(?:overall\s+)?grade:?\s*([A-F][+-]?)/i)
        match[1]
      elsif match = response.match(/grade:\s*([A-F][+-]?)/i)
        match[1]
      else
        "Not graded"
      end
    end

    def extract_scores(response)
      scores = {}
      # Look for specific score patterns
      if section = response.match(/scores[:\s]+(.*?)(?=(strengths|opportunities|overall|grade|feedback)|\Z)/im)
        section_text = section[1]

        # Parse scores in format "Category: X/Y" or "Category: X"
        section_text.scan(/([A-Za-z\s]+):\s*(\d+)(?:\/\d+)?/i) do |category, score|
          scores[category.strip] = score.to_i
        end
      end

      scores
    end
  end
end
