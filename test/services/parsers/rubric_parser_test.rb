# frozen_string_literal: true

require "test_helper"

class Parsers::RubricParserTest < ActiveSupport::TestCase
  setup do
    @parser = Parsers::RubricParser.new

    @valid_response = {
      title: "Essay Writing Rubric",
      criteria: [
        {
          title: "Thesis Statement",
          description: "Clarity and effectiveness of thesis",
          points: 20,
          levels: [
            { title: "Excellent", description: "Thesis is clear and insightful", points: 20 },
            { title: "Proficient", description: "Thesis is clear", points: 15 },
            { title: "Developing", description: "Thesis needs development", points: 10 },
            { title: "Beginning", description: "Thesis is unclear or missing", points: 5 }
          ]
        },
        {
          title: "Evidence",
          description: "Use of relevant evidence",
          points: 15,
          levels: [
            { title: "Excellent", description: "Strong evidence throughout", points: 15 },
            { title: "Proficient", description: "Adequate evidence", points: 10 },
            { title: "Beginning", description: "Little or no evidence", points: 5 }
          ]
        }
      ]
    }.to_json
  end

  test "should parse valid rubric response" do
    # Exercise
    result = @parser.parse(@valid_response)

    # Verify
    assert_equal "Essay Writing Rubric", result[:title]
    assert_equal 35, result[:total_points]  # 20 + 15

    # Check criteria
    assert_equal 2, result[:criteria].size
    assert_equal "Thesis Statement", result[:criteria][0][:title]
    assert_equal 1, result[:criteria][0][:position]
    assert_equal 20, result[:criteria][0][:points]

    # Check levels
    assert_equal 4, result[:criteria][0][:levels].size
    assert_equal "Excellent", result[:criteria][0][:levels][0][:title]
    assert_equal 20, result[:criteria][0][:levels][0][:points]
    assert_equal 1, result[:criteria][0][:levels][0][:position]
  end

  test "should handle empty arrays in response" do
    # Setup
    response_with_empty_arrays = {
      title: "Empty Rubric",
      criteria: []
    }.to_json

    # Exercise
    result = @parser.parse(response_with_empty_arrays)

    # Verify
    assert_equal "Empty Rubric", result[:title]
    assert_equal 0, result[:total_points]
    assert_equal [], result[:criteria]
  end

  test "should handle missing levels in criteria" do
    # Setup
    response_with_missing_levels = {
      title: "Incomplete Rubric",
      criteria: [
        {
          title: "Criterion without levels",
          description: "A criterion with no levels defined",
          points: 10
        }
      ]
    }.to_json

    # Exercise
    result = @parser.parse(response_with_missing_levels)

    # Verify
    assert_equal 1, result[:criteria].size
    assert_equal "Criterion without levels", result[:criteria][0][:title]
    assert_equal [], result[:criteria][0][:levels]
  end

  test "should calculate total points correctly" do
    # Setup
    response_with_points = {
      title: "Point Calculation Test",
      criteria: [
        { title: "C1", description: "D1", points: 10, levels: [] },
        { title: "C2", description: "D2", points: 20, levels: [] },
        { title: "C3", description: "D3", points: 15, levels: [] }
      ]
    }.to_json

    # Exercise
    result = @parser.parse(response_with_points)

    # Verify
    assert_equal 45, result[:total_points]  # 10 + 20 + 15
  end

  test "should raise error for invalid JSON" do
    # Setup
    invalid_json = '{"title": "Invalid Rubric", "criteria": ['

    # Exercise & Verify
    assert_raises Parsers::ParseError do
      @parser.parse(invalid_json)
    end
  end
end
