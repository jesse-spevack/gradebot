require "test_helper"

class GradingServiceTest < ActiveSupport::TestCase
  setup do
    # Setup for feature flag testing
    @user = users(:admin)
    @feature_flag_service = FeatureFlagService.new

    # Ensure the LLM feature flag exists
    flag = FeatureFlag.find_or_create_by(key: "llm_enabled") do |f|
      f.name = "LLM Enabled"
      f.enabled = false
    end

    # Reset LLM enabled status before each test
    @feature_flag_service.disable("llm_enabled", @user)

    # Sample inputs for testing
    @document_content = "This is a sample essay about climate change. The Earth is warming due to human activities."
    @assignment_prompt = "Write a 500-word essay about climate change."
    @grading_rubric = "Content: 40%, Structure: 30%, Grammar: 30%"
  end

  test "exists as a service class" do
    assert_kind_of Class, GradingService
  end

  test "initializes with default configuration" do
    service = GradingService.new

    # Should use the default config for grade_assignment
    assert_kind_of GradingService, service
  end

  test "initializes with custom configuration" do
    custom_config = { provider: :openai, model: "gpt-4", temperature: 0.5 }
    service = GradingService.new(custom_config)

    assert_kind_of GradingService, service
  end

  test "returns error message when LLM is disabled" do
    # Ensure LLM is disabled
    @feature_flag_service.disable("llm_enabled", @user)

    service = GradingService.new
    result = service.grade_submission(@document_content, @assignment_prompt, @grading_rubric)

    assert_includes result.keys, :error
    assert_match /LLM grading is not enabled/, result[:error]
    assert_includes result.keys, :feedback
    assert_match /LLM grading is not enabled/, result[:feedback]
  end

  test "grades submission successfully when LLM is enabled" do
    # Enable LLM for this test
    @feature_flag_service.enable("llm_enabled", @user)

    # Create a mock response
    mock_response = {
      content: "Feedback: Good essay but lacks depth.\nGrade: B\nScores: Content=30/40, Structure=25/30, Grammar=28/30",
      metadata: { tokens: { total: 100 } }
    }

    # Create a mock client
    mock_client = mock("llm_client")

    # Expect the generate method to be called with a prompt containing our inputs
    mock_client.expects(:generate).returns(mock_response)

    # Stub the client factory to return our mock client
    LLM::ClientFactory.stubs(:create).returns(mock_client)

    # Test the service
    service = GradingService.new
    result = service.grade_submission(@document_content, @assignment_prompt, @grading_rubric)

    # Verify the response
    assert_nil result[:error]
    assert_equal mock_response[:content], result[:feedback]
    assert_equal "B", result[:grade]
    assert_kind_of Hash, result[:rubric_scores]
  end

  test "extracts grade from response" do
    service = GradingService.new

    # Test different grade formats
    assert_equal "A", service.send(:extract_grade, "Overall Grade: A")
    assert_equal "B+", service.send(:extract_grade, "The grade is B+")
    assert_equal "C-", service.send(:extract_grade, "grade: C-")
    assert_equal "F", service.send(:extract_grade, "Grade: F for this submission")

    # When no grade is found
    assert_equal "Ungraded", service.send(:extract_grade, "No grade mentioned here")
  end

  test "handles errors from LLM client" do
    # Enable LLM for this test
    @feature_flag_service.enable("llm_enabled", @user)

    # Stub the client factory to raise an error
    LLM::ClientFactory.stubs(:create).raises(StandardError.new("LLM API error"))

    # Test the service
    service = GradingService.new
    result = service.grade_submission(@document_content, @assignment_prompt, @grading_rubric)

    # Verify the response contains error information
    assert_includes result.keys, :error
    assert_match /LLM API error/, result[:error]
    assert_includes result.keys, :feedback
    assert_match /Error during grading/, result[:feedback]
  end

  test "builds appropriate grading prompt" do
    service = GradingService.new
    prompt = service.send(:build_grading_prompt, @document_content, @assignment_prompt, @grading_rubric)

    # Verify prompt structure and content
    assert_kind_of String, prompt
    assert_includes prompt, @document_content
    assert_includes prompt, @assignment_prompt
    assert_includes prompt, @grading_rubric
    assert_includes prompt, "Please grade this submission"
  end

  test "extracts rubric scores from response" do
    service = GradingService.new

    # Sample LLM response with scores
    response = <<~RESPONSE
      The essay addresses climate change well.

      Content: 35/40
      Structure: 25/30
      Grammar: 28/30

      Overall Grade: B+
    RESPONSE

    scores = service.send(:extract_rubric_scores, response, @grading_rubric)

    # Verify extracted scores
    assert_equal 35, scores[:content]
    assert_equal 25, scores[:structure]
    assert_equal 28, scores[:grammar]
  end
end
