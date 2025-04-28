# frozen_string_literal: true

require "test_helper"

class Parsers::SummaryFeedbackParserTest < ActiveSupport::TestCase
  setup do
    @parser = Parsers::SummaryFeedbackParser.new

    @valid_response = {
      submissions_count: 25,
      average_grade: 82.5,
      grade_distribution: {
        "A": 5,
        "B": 10,
        "C": 8,
        "D": 2,
        "F": 0
      },
      common_strengths: [
        { title: "Strong introductions", description: "Most students wrote effective introductions", frequency: 75 },
        { title: "Good use of sources", description: "Students cited sources properly", frequency: 65 }
      ],
      common_areas_for_improvement: [
        { title: "Conclusion development", description: "Many conclusions lacked depth", frequency: 60 },
        { title: "Grammar and mechanics", description: "Several papers had mechanical errors", frequency: 55 }
      ],
      insights: "Students generally understood the main concepts but struggled with application.",
      recommendations: "Focus future instruction on practical application of concepts."
    }.to_json
  end

  test "should parse valid summary feedback response" do
    # Exercise
    result = @parser.parse(@valid_response)

    # Verify
    assert_equal 25, result[:submissions_count]
    assert_equal 82.5, result[:average_grade]
    assert_equal({ "A" => 5, "B" => 10, "C" => 8, "D" => 2, "F" => 0 }, result[:grade_distribution].transform_keys(&:to_s))

    # Check common strengths
    assert_equal 2, result[:common_strengths].size
    assert_equal "Strong introductions", result[:common_strengths][0][:title]
    assert_equal 75, result[:common_strengths][0][:frequency]
    assert_equal "strength", result[:common_strengths][0][:kind]

    # Check common opportunities
    assert_equal 2, result[:common_opportunities].size
    assert_equal "Conclusion development", result[:common_opportunities][0][:title]
    assert_equal "opportunity", result[:common_opportunities][0][:kind]

    # Check insights and recommendations
    assert_equal "Students generally understood the main concepts but struggled with application.", result[:insights]
    assert_equal "Focus future instruction on practical application of concepts.", result[:recommendations]
  end

  test "should handle empty arrays in response" do
    # Setup
    response_with_empty_arrays = {
      submissions_count: 0,
      average_grade: 0,
      grade_distribution: {},
      common_strengths: [],
      common_areas_for_improvement: [],
      insights: "",
      recommendations: ""
    }.to_json

    # Exercise
    result = @parser.parse(response_with_empty_arrays)

    # Verify
    assert_equal 0, result[:submissions_count]
    assert_equal [], result[:common_strengths]
    assert_equal [], result[:common_opportunities]
  end

  test "should handle missing sections in response" do
    # Setup
    response_with_missing_sections = {
      submissions_count: 15,
      average_grade: 78.3
    }.to_json

    # Exercise
    result = @parser.parse(response_with_missing_sections)

    # Verify
    assert_equal 15, result[:submissions_count]
    assert_equal 78.3, result[:average_grade]
    assert_equal [], result[:common_strengths]
    assert_equal [], result[:common_opportunities]
    assert_nil result[:insights]
    assert_nil result[:recommendations]
  end

  test "should raise error for invalid JSON" do
    # Setup
    invalid_json = '{"submissions_count": 25, "common_strengths": ['

    # Exercise & Verify
    assert_raises Parsers::ParseError do
      @parser.parse(invalid_json)
    end
  end
end
