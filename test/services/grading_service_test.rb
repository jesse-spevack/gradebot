# frozen_string_literal: true

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

    # Set up consistent LLM configuration for tests
    stub_llm_enabled(false) # Start with LLM disabled
  end

  test "exists as a service class" do
    assert_kind_of Class, GradingService
  end

  test "initializes with default configuration" do
    # Use our test configuration
    test_config = { provider: :test, model: "test-model", temperature: 0.5 }
    stub_task_config(:grade_assignment, test_config)

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
    # Ensure LLM is disabled via our helper
    stub_llm_enabled(false)

    service = GradingService.new
    result = service.grade_submission(@document_content, @assignment_prompt, @grading_rubric)

    assert_equal "LLM grading is not enabled. Please contact an administrator.", result.error
  end

  test "grades submission successfully when LLM is enabled" do
    # Enable LLM for this test using our helper
    stub_llm_enabled(true)

    # Create a mock response with JSON content matching the expected format
    mock_json = {
      "feedback": "Feedback: Good essay but lacks depth.",
      "strengths": [ "Good introduction", "Clear thesis statement" ],
      "opportunities": [ "Add more supporting evidence", "Improve conclusion" ],
      "overall_grade": "B",
      "scores": { "Content": 30, "Structure": 25, "Grammar": 28 }
    }

    # Create a mock response using our helper
    mock_response = mock_llm_response(JSON.generate(mock_json))

    # Create a mock client using our helper
    mock_client = mock_llm_client(mock_response)

    # Stub PromptTemplate to return a test prompt
    test_prompt = "Test prompt with document, assignment, and rubric"
    PromptTemplate.stubs(:render).with(:grading, anything).returns(test_prompt)

    # Stub ResponseParser to return a GradingResult
    mock_result = GradingResponse.new(
      feedback: "Feedback: Good essay but lacks depth.",
      strengths: [ "Good introduction", "Clear thesis statement" ],
      opportunities: [ "Add more supporting evidence", "Improve conclusion" ],
      overall_grade: "B",
      rubric_scores: { "Content" => 30, "Structure" => 25, "Grammar" => 28 }
    )
    ResponseParser.stubs(:parse).returns(mock_result)

    # Expect the generate method to be called with our test prompt
    mock_client.expects(:generate).with({ prompt: test_prompt }).returns(mock_response)

    # Stub the client factory to return our mock client
    LLM::ClientFactory.stubs(:create).returns(mock_client)

    # Test the service
    service = GradingService.new
    result = service.grade_submission(@document_content, @assignment_prompt, @grading_rubric)

    # Verify the response
    assert_nil result.error
    assert_equal "Feedback: Good essay but lacks depth.", result.feedback
    assert_equal [ "Good introduction", "Clear thesis statement" ], result.strengths
    assert_equal [ "Add more supporting evidence", "Improve conclusion" ], result.opportunities
    assert_equal "B", result.overall_grade
    assert_kind_of Hash, result.rubric_scores
    assert_equal 30, result.rubric_scores["Content"]
  end

  test "handles parsing errors gracefully" do
    # Enable LLM for this test using our helper
    stub_llm_enabled(true)

    # Create a mock client and response using our helpers
    mock_client = mock_llm_client
    mock_response = mock_llm_response("Invalid JSON or structured text")

    # Set up expectations and stubs
    mock_client.stubs(:generate).returns(mock_response)
    LLM::ClientFactory.stubs(:create).returns(mock_client)

    # Stub PromptTemplate to return a test prompt
    PromptTemplate.stubs(:render).returns("Test prompt")

    # Stub ResponseParser to raise a ParsingError
    parsing_error = ParsingError.new("Failed to parse response", [
      { strategy: "JsonStrategy", error: "Invalid JSON" }
    ])
    ResponseParser.stubs(:parse).raises(parsing_error)

    # Stub Rails logger to avoid formatting issues in tests
    Rails.logger.stubs(:error)

    # Stub the GradingLogger to allow any calls
    GradingLogger.stubs(:log_grading_error)

    # Test the service
    service = GradingService.new
    result = service.grade_submission(@document_content, @assignment_prompt, @grading_rubric)

    # Verify the response contains error information
    assert_includes result.error, "Failed to parse LLM response"
  end

  test "handles errors from LLM client" do
    # Enable LLM for this test using our helper
    stub_llm_enabled(true)

    # Stub PromptTemplate to return a test prompt
    PromptTemplate.stubs(:render).returns("Test prompt")

    # Stub the client factory to raise an error
    LLM::ClientFactory.stubs(:create).raises(StandardError.new("LLM API error"))

    # Stub Rails logger to avoid formatting issues in tests
    Rails.logger.stubs(:error)

    # Stub the GradingLogger to allow any calls
    GradingLogger.stubs(:log_grading_error)

    # Test the service
    service = GradingService.new
    result = service.grade_submission(@document_content, @assignment_prompt, @grading_rubric)

    # Verify the response contains error information
    assert_includes result.error, "Error during grading"
  end

  test "uses ContentCleaner to clean document content" do
    # Test with document containing tabs and unusual characters
    dirty_content = "Line 1\tWith tab\nLine 2\r\nWith different newline\u0000Null char"
    clean_content = ContentCleaner.clean(dirty_content)

    # Verify content was cleaned
    refute_includes clean_content, "\t"
    refute_includes clean_content, "\r"
    refute_includes clean_content, "\u0000"
    assert_includes clean_content, "Line 1"
    assert_includes clean_content, "Line 2"
  end

  teardown do
    # Clean up all stubs
    unstub_all_llm_configuration
  end
end
