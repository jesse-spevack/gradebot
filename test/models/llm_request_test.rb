# frozen_string_literal: true

require "test_helper"

class LLMRequestTest < ActiveSupport::TestCase
  test "initializes with default values" do
    request = LLMRequest.new(prompt: "Test prompt", request_type: "test")

    assert_equal "Test prompt", request.prompt
    assert_equal "test", request.request_type
    assert_equal 0.7, request.temperature
    assert_equal 1000, request.max_tokens
    assert_not_nil request.request_id
    assert_equal({}, request.metadata)
  end

  test "validates presence of required fields" do
    # Missing prompt
    request = LLMRequest.new(llm_model_name: "claude-3-5-haiku", request_type: "test")
    assert_not request.valid?
    assert_includes request.errors[:prompt], "can't be blank"

    # Test llm_model_name validation
    request = LLMRequest.new(prompt: "Test prompt", request_type: "test")
    request.llm_model_name = nil # Override the default value after initialization
    assert_not request.valid?
    assert_includes request.errors[:llm_model_name], "can't be blank"

    # Missing request_type
    request = LLMRequest.new(prompt: "Test prompt", llm_model_name: "claude-3-5-haiku")
    assert_not request.valid?
    assert_includes request.errors[:request_type], "can't be blank"

    # Valid request
    request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-haiku",
      request_type: "test"
    )
    assert request.valid?
  end

  test "validates numerical parameters" do
    # Invalid temperature (too high)
    request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-haiku",
      request_type: "test",
      temperature: 1.5
    )
    assert_not request.valid?
    assert_includes request.errors[:temperature], "must be less than or equal to 1"

    # Invalid temperature (negative)
    request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-haiku",
      request_type: "test",
      temperature: -0.1
    )
    assert_not request.valid?
    assert_includes request.errors[:temperature], "must be greater than or equal to 0"

    # Invalid max_tokens (negative)
    request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-haiku",
      request_type: "test",
      max_tokens: -100
    )
    assert_not request.valid?
    assert_includes request.errors[:max_tokens], "must be greater than 0"

    # Invalid max_tokens (not an integer)
    request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-haiku",
      request_type: "test",
      max_tokens: 1.5
    )
    assert_not request.valid?
    assert_includes request.errors[:max_tokens], "must be an integer"
  end

  test "to_api_parameters returns correctly formatted parameters" do
    request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-haiku",
      request_type: "test",
      temperature: 0.5,
      max_tokens: 500
    )

    params = request.to_api_parameters

    assert_equal "Test prompt", params[:prompt]
    assert_equal "claude-3-5-haiku", params[:llm_model_name]
    assert_equal 0.5, params[:temperature]
    assert_equal 500, params[:max_tokens]
  end

  test "to_context returns tracking context" do
    user = users(:teacher)
    submission = student_submissions(:pending_submission)
    metadata = { source: "test" }
    request_id = "test-uuid"

    request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-haiku",
      request_type: "test",
      user: user,
      trackable: submission,
      metadata: metadata,
      request_id: request_id
    )

    context = request.to_context

    assert_equal request_id, context[:request_id]
    assert_equal "test", context[:request_type]
    assert_equal "claude-3-5-haiku", context[:llm_model_name]
    assert_equal user, context[:user]
    assert_equal submission, context[:trackable]
    assert_equal metadata, context[:metadata]
  end

  test "to_input creates input for LLMClient" do
    request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "claude-3-5-haiku",
      request_type: "test"
    )

    input = request.to_input

    assert_equal "Test prompt", input[:prompt]
    assert_equal request.to_context, input[:context]
  end
end
