module Strategies
  # StructuredTextStrategy extracts data from text that has a clear section-based structure
  #
  # This strategy is used as a last resort when other strategies fail. It looks for
  # sections in the text that are clearly delimited by headers like:
  # - "FEEDBACK"
  # - "STRENGTHS"
  # - "OPPORTUNITIES"
  # - "GRADE"
  # - "SCORES"
  #
  # It splits the text into these sections and then processes each section appropriately.
  # This strategy works well when the LLM provides a clearly structured response with
  # consistent section headers, even if it doesn't follow the JSON format.
  class StructuredTextStrategy
    def parse(response)
      # Identify sections based on headers or markers
      sections = split_into_sections(response)

      feedback = sections[:feedback] || ""
      strengths = parse_list_section(sections[:strengths])
      opportunities = parse_list_section(sections[:opportunities])
      overall_grade = extract_grade_from_section(sections[:grade])
      scores = parse_scores_section(sections[:scores])

      GradingResponse.new(
        feedback: feedback,
        strengths: strengths,
        opportunities: opportunities,
        overall_grade: overall_grade,
        rubric_scores: scores
      )
    end

    private

    def split_into_sections(response)
      # Split the response based on section headers
      sections = {}

      # Define common section markers
      markers = {
        feedback: [ /feedback/i, /comments/i ],
        strengths: [ /strengths/i, /positive/i, /good points/i ],
        opportunities: [ /opportunities/i, /areas for improvement/i, /weaknesses/i ],
        grade: [ /overall grade/i, /grade/i, /final score/i ],
        scores: [ /scores/i, /rubric scores/i, /criteria scores/i ]
      }

      # For each potential section, find the text
      section_positions = []

      markers.each do |section, patterns|
        patterns.each do |pattern|
          if match = response.match(/(?:^|\n)\s*(#{pattern.source}).*?:/i)
            position = match.begin(0)
            section_positions << [ position, section, match[0] ]
          end
        end
      end

      # Sort positions and extract sections
      section_positions.sort_by!(&:first)

      # Extract text between markers
      section_positions.each_with_index do |(pos, section, header), index|
        next_pos = if index < section_positions.size - 1
                     section_positions[index + 1][0]
        else
                     response.length
        end

        # Get content between this header and the next one
        content = response[pos + header.length...next_pos].strip

        # Remove the header part from content if it's still there
        content = content.sub(/^.*?:/m, "")

        sections[section] = content.strip
      end

      # If no sections found using the header approach, try to split by double newlines
      if sections.empty?
        paragraphs = response.split(/\n\s*\n/).map(&:strip).reject(&:empty?)

        # Assign paragraphs to sections based on content patterns
        sections[:feedback] = paragraphs.first if paragraphs.any?

        strengths_paragraph = paragraphs.find { |p| p =~ /strength|positive|good/i }
        sections[:strengths] = strengths_paragraph if strengths_paragraph

        opportunities_paragraph = paragraphs.find { |p| p =~ /opportunit|improv|weak/i }
        sections[:opportunities] = opportunities_paragraph if opportunities_paragraph

        grade_paragraph = paragraphs.find { |p| p =~ /grade|score|mark/i }
        sections[:grade] = grade_paragraph if grade_paragraph
      end

      sections
    end

    def parse_list_section(section_text)
      return [] unless section_text

      # Try to identify list items
      items = []

      # Check for bullet points
      if bullet_items = section_text.scan(/[-*•]\s*(.+?)(?=[-*•]|\Z|\n\n)/m)
        items = bullet_items.flatten.map(&:strip)
      # Check for numbered items
      elsif numbered_items = section_text.scan(/\d+\.\s*(.+?)(?=\d+\.|\Z|\n\n)/m)
        items = numbered_items.flatten.map(&:strip)
      # Fallback: split by newlines and filter
      else
        items = section_text.split(/[\n\r]+/).map(&:strip).reject(&:empty?)
      end

      items
    end

    def extract_grade_from_section(section_text)
      return "Not graded" unless section_text

      # Try to extract a letter grade
      if match = section_text.match(/([A-F][+-]?)/i)
        match[1]
      else
        "Not clearly specified"
      end
    end

    def parse_scores_section(section_text)
      Rails.logger.debug("StructuredTextStrategy: parse_scores_section called with: #{section_text.inspect}")

      scores = {}
      return scores unless section_text

      # Parse scores in various formats
      begin
        section_text.scan(/([A-Za-z\s]+)[:\-]\s*(\d+)(?:[\/\\](\d+))?/i) do |category, score, total|
          category_name = category.strip
          score_value = score.to_i
          Rails.logger.debug("StructuredTextStrategy: Found score '#{category_name}': #{score_value}")
          scores[category_name] = score_value
        end
      rescue => e
        Rails.logger.error("StructuredTextStrategy: Error parsing scores: #{e.message}")
        # Return empty hash on error
        return {}
      end

      Rails.logger.debug("StructuredTextStrategy: Final scores: #{scores.inspect}")
      scores
    end
  end
end
