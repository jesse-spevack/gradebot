# frozen_string_literal: true

module Parsers
  # Parses LLM responses for assignment summary feedback
  class SummaryFeedbackParser < BaseResponseParser
    # Parse the response into a structured format
    # @param response [String] The raw response from the LLM
    # @return [Hash] The parsed summary data
    def parse(response)
      json_data = parse_json(response)

      {
        submissions_count: json_data["submissions_count"],
        average_grade: json_data["average_grade"],
        grade_distribution: json_data["grade_distribution"],
        common_strengths: parse_feedback_items(json_data["common_strengths"], "strength"),
        common_opportunities: parse_feedback_items(json_data["common_areas_for_improvement"], "opportunity"),
        insights: json_data["insights"],
        recommendations: json_data["recommendations"]
      }
    end

    private

    # Parse an array of feedback items into structured data
    # @param items [Array] The raw feedback items
    # @param kind [String] The kind of feedback (strength or opportunity)
    # @return [Array<Hash>] Array of structured feedback items
    def parse_feedback_items(items, kind)
      return [] unless items.is_a?(Array)

      items.map do |item|
        {
          title: item["title"],
          description: item["description"],
          frequency: item["frequency"],
          kind: kind
        }
      end
    end
  end
end
