module Strategies
  # FixedJsonStrategy attempts to repair common JSON formatting issues before parsing
  #
  # This strategy is used when the first direct JSON parsing attempt fails.
  # It handles common LLM JSON errors such as:
  # - Unescaped quotes within string values
  # - JSON embedded in other text (extracts the JSON portion)
  # - Single quotes instead of double quotes
  # - Missing quotes around keys
  # - Trailing commas
  #
  # By addressing these common issues, we can often recover valid data from
  # slightly malformed JSON responses.
  class FixedJsonStrategy
    def parse(response)
      # Try to identify and extract JSON objects
      json_pattern = /\{.*\}/m
      if match = response.match(json_pattern)
        # Extract the match and try to fix common issues
        json_text = match[0]
        fixed_json = fix_common_json_issues(json_text)

        # Try parsing the fixed JSON
        json = JSON.parse(fixed_json)

        # Create a GradingResponse from the parsed JSON
        GradingResponse.new(
          feedback: json["feedback"],
          strengths: json["strengths"],
          opportunities: json["opportunities"],
          overall_grade: json["overall_grade"],
          rubric_scores: json["scores"]
        )
      else
        raise "No JSON-like structure found in response"
      end
    end

    private

    def fix_common_json_issues(json_text)
      # Fix unescaped quotes in values
      json_text = json_text.gsub(/:\s*"([^"]*)"([^,\}]*)([,\}])/) do |match|
        value = $1
        extra = $2
        terminator = $3
        %Q(:"#{value}"#{terminator})
      end

      # Fix unquoted property names
      json_text = json_text.gsub(/(\{|\,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:/) do |match|
        delimiter = $1
        prop_name = $2
        %Q(#{delimiter}"#{prop_name}":)
      end

      # Fix trailing commas in arrays/objects
      json_text = json_text.gsub(/,\s*\}/, "}").gsub(/,\s*\]/, "]")

      # Fix single quotes used instead of double quotes
      json_text = json_text.gsub(/'([^']*)'/) do |match|
        value = $1
        %Q("#{value.gsub(/"/, '\\"')}")
      end

      # Ensure double quotes are properly escaped
      json_text = json_text.gsub(/(?<!\\)"([^"\\]*)\\([^"\\])([^"]*)"/) do |match|
        prefix = $1
        slash = $2
        suffix = $3
        %Q("#{prefix}\\\\#{slash}#{suffix}")
      end

      # Return the cleaned JSON
      json_text
    end
  end
end
