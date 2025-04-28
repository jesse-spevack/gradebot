# frozen_string_literal: true

module Parsers
  # Parses LLM responses for student work grading
  class StudentWorkParser < BaseResponseParser
    # Parse the response into a structured format
    # @param response [String] The raw response from the LLM
    # @return [Hash] The parsed feedback data
    def parse(response)
      json_data = parse_json(response)

      {
        overall_grade: json_data["overall_grade"],
        overall_feedback: json_data["overall_feedback"],
        strengths: parse_feedback_items(json_data["strengths"], "strength"),
        opportunities: parse_feedback_items(json_data["areas_for_improvement"], "opportunity"),
        rubric_scores: parse_rubric_scores(json_data["rubric_scores"])
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
          kind: kind
        }
      end
    end

    # Parse rubric scores into structured data
    # @param scores [Array] The raw rubric scores
    # @return [Array<Hash>] Array of structured rubric scores
    def parse_rubric_scores(scores)
      return [] unless scores.is_a?(Array)

      scores.map do |score|
        {
          criterion_id: score["criterion_id"],
          level_id: score["level_id"],
          points: score["points"],
          reason: score["reason"],
          evidence: score["evidence"]
        }
      end
    end
  end
end
