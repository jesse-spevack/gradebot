# frozen_string_literal: true

module Parsers
  # Parses LLM responses for rubric generation
  class RubricParser < BaseResponseParser
    # Parse the response into a structured format
    # @param response [String] The raw response from the LLM
    # @return [Hash] The parsed rubric data
    def parse(response)
      json_data = parse_json(response)

      {
        title: json_data["title"],
        total_points: calculate_total_points(json_data["criteria"]),
        criteria: parse_criteria(json_data["criteria"])
      }
    end

    private

    # Parse criteria into structured data
    # @param criteria [Array] The raw criteria
    # @return [Array<Hash>] Array of structured criteria
    def parse_criteria(criteria)
      return [] unless criteria.is_a?(Array)

      criteria.map.with_index do |criterion, index|
        {
          title: criterion["title"],
          description: criterion["description"],
          position: index + 1,
          points: criterion["points"],
          levels: parse_levels(criterion["levels"])
        }
      end
    end

    # Parse levels into structured data
    # @param levels [Array] The raw levels
    # @return [Array<Hash>] Array of structured levels
    def parse_levels(levels)
      return [] unless levels.is_a?(Array)

      levels.map.with_index do |level, index|
        {
          title: level["title"],
          description: level["description"],
          points: level["points"],
          position: index + 1
        }
      end
    end

    # Calculate the total points for a rubric
    # @param criteria [Array] The raw criteria
    # @return [Integer] The total points
    def calculate_total_points(criteria)
      return 0 unless criteria.is_a?(Array)

      criteria.sum do |criterion|
        criterion["points"].to_i
      end
    end
  end
end
