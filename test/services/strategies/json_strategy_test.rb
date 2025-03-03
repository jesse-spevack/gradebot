# frozen_string_literal: true

require "test_helper"

class Strategies::JsonStrategyTest < ActiveSupport::TestCase
  include LLMConfigurationHelper

  setup do
    # Initialize the strategy
    @strategy = Strategies::JsonStrategy.new

    # Create a valid JSON response for testing
    @valid_json = <<~JSON
      {
        "feedback": "This is feedback",
        "strengths": ["Strength 1", "Strength 2"],
        "opportunities": ["Opportunity 1", "Opportunity 2"],
        "overall_grade": "A",
        "scores": { "criterion1": 4, "criterion2": 3 }
      }
    JSON

    # Create an invalid JSON response
    @invalid_json = "This is not JSON"
  end

  test "parse accepts only one argument" do
    assert_equal 1, @strategy.method(:parse).arity
  end

  test "parse with valid JSON returns valid GradingResponse" do
    result = @strategy.parse(@valid_json)
    assert result.success?
    assert_equal "This is feedback", result.feedback
    assert_equal [ "Strength 1", "Strength 2" ], result.strengths
    assert_equal [ "Opportunity 1", "Opportunity 2" ], result.opportunities
    assert_equal "A", result.overall_grade
    assert_equal({ "criterion1" => 4, "criterion2" => 3 }, result.rubric_scores)
  end

  test "parse with invalid JSON raises error" do
    assert_raises JSON::ParserError do
      @strategy.parse(@invalid_json)
    end
  end

  test "LLMConfigurationHelper correctly detects JsonStrategy arity" do
    assert_not StrategyConfigurationHelper.accepts_context?(@strategy)
  end

  test "LLMConfigurationHelper correctly calls JsonStrategy parse method" do
    result = StrategyConfigurationHelper.call_parse(@strategy, @valid_json, { some: "context" })
    assert result.success?
    assert_equal "This is feedback", result.feedback
  end

  test "works with ResponseParser integration" do
    # Create a mock result
    mock_result = GradingResponse.new(
      feedback: "Test feedback",
      strengths: [ "Test strength" ],
      opportunities: [ "Test opportunity" ],
      overall_grade: "A",
      rubric_scores: { "test" => 5 }
    )

    # Mock JSON.parse to return our test data
    JSON.stubs(:parse).with(@valid_json).returns({
      "feedback" => "Test feedback",
      "strengths" => [ "Test strength" ],
      "opportunities" => [ "Test opportunity" ],
      "overall_grade" => "A",
      "scores" => { "test" => 5 }
    })

    # Mock the logging to avoid errors during test
    GradingLogger.stubs(:capture_parsing_attempt).returns({})
    GradingLogger.stubs(:log_parsing_success)

    # Test the parsing
    result = ResponseParser.parse(@valid_json)
    assert_equal "Test feedback", result.feedback
    assert_equal [ "Test strength" ], result.strengths
    assert_equal [ "Test opportunity" ], result.opportunities
    assert_equal "A", result.overall_grade
    assert_equal({ "test" => 5 }, result.rubric_scores)
  end
end
