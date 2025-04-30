# frozen_string_literal: true

require "test_helper"

class Parsers::StudentWorkParserTest < ActiveSupport::TestCase
  setup do
    @parser = Parsers::StudentWorkParser.new

    @valid_response = {
      overall_grade: 85,
      overall_feedback: "Good work overall.",
      strengths: [
        { title: "Strong thesis", description: "Your thesis is clear and effective." },
        { title: "Good evidence", description: "You use strong evidence to support your points." }
      ],
      areas_for_improvement: [
        { title: "Grammar issues", description: "There are several grammatical errors." },
        { title: "Citation format", description: "Citation format is inconsistent." }
      ],
      rubric_scores: [
        { criterion_id: 1, level_id: 2, points: 18, reason: "Clear thesis", evidence: "First paragraph" },
        { criterion_id: 2, level_id: 1, points: 15, reason: "Some evidence", evidence: "Middle paragraphs" }
      ]
    }.to_json
  end

  test "should parse valid student work response" do
    # Exercise
    result = @parser.parse(@valid_response)

    # Verify
    assert_equal 85, result[:overall_grade]
    assert_equal "Good work overall.", result[:overall_feedback]

    # Check strengths
    assert_equal 2, result[:strengths].size
    assert_equal "Strong thesis", result[:strengths][0][:title]
    assert_equal "strength", result[:strengths][0][:kind]

    # Check opportunities
    assert_equal 2, result[:opportunities].size
    assert_equal "Grammar issues", result[:opportunities][0][:title]
    assert_equal "opportunity", result[:opportunities][0][:kind]

    # Check rubric scores
    assert_equal 2, result[:rubric_scores].size
    assert_equal 1, result[:rubric_scores][0][:criterion_id]
    assert_equal 18, result[:rubric_scores][0][:points]
  end

  test "should handle empty arrays in response" do
    # Setup
    response_with_empty_arrays = {
      overall_grade: 85,
      overall_feedback: "Good work overall.",
      strengths: [],
      areas_for_improvement: [],
      rubric_scores: []
    }.to_json

    # Exercise
    result = @parser.parse(response_with_empty_arrays)

    # Verify
    assert_equal [], result[:strengths]
    assert_equal [], result[:opportunities]
    assert_equal [], result[:rubric_scores]
  end

  test "should handle missing sections in response" do
    # Setup
    response_with_missing_sections = {
      overall_grade: 85,
      overall_feedback: "Good work overall."
    }.to_json

    # Exercise
    result = @parser.parse(response_with_missing_sections)

    # Verify
    assert_equal [], result[:strengths]
    assert_equal [], result[:opportunities]
    assert_equal [], result[:rubric_scores]
  end

  test "should raise error for invalid JSON" do
    # Setup
    invalid_json = '{"overall_grade": 85, "strengths": ['

    # Exercise & Verify
    assert_raises Parsers::ParseError do
      @parser.parse(invalid_json)
    end
  end
end
