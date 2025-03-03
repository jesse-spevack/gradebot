# frozen_string_literal: true

require "test_helper"

class ResponseParserTest < ActiveSupport::TestCase
  setup do
    @valid_json_response = '{
      "feedback": "This is feedback",
      "strengths": ["Strength 1", "Strength 2"],
      "opportunities": ["Opportunity 1", "Opportunity 2"],
      "overall_grade": "B+",
      "scores": {"Content": 8, "Organization": 9}
    }'
  end

  test "parses valid JSON response" do
    result = ResponseParser.parse(@valid_json_response)
    assert result.success?
    assert_equal "This is feedback", result.feedback
    assert_equal [ "Strength 1", "Strength 2" ], result.strengths
    assert_equal [ "Opportunity 1", "Opportunity 2" ], result.opportunities
    assert_equal "B+", result.overall_grade
    assert_equal({ "Content" => 8, "Organization" => 9 }, result.rubric_scores)
  end

  test "returns error for blank response" do
    result = ResponseParser.parse("")
    assert_not result.success?
    assert_equal "No response to parse", result.error
  end

  test "tries other strategies when JSON parsing fails" do
    invalid_json = "not valid json"
    mock_strategy = mock("TestStrategy")
    mock_strategy.expects(:parse).with(invalid_json).returns(
      GradingResponse.new(
        feedback: "test feedback",
        strengths: [ "test" ],
        opportunities: [ "test" ]
      )
    )

    ResponseParser.stubs(:strategies).returns([ mock_strategy ])

    result = ResponseParser.parse(invalid_json)
    assert result.success?
    assert_equal "test feedback", result.feedback
  end

  test "raises error when all strategies fail" do
    invalid_json = "not valid json"
    mock_strategy = mock("TestStrategy")
    mock_strategy.expects(:parse).raises(StandardError.new("test error"))

    ResponseParser.stubs(:strategies).returns([ mock_strategy ])

    assert_raises StandardError do
      ResponseParser.parse(invalid_json)
    end
  end
end
