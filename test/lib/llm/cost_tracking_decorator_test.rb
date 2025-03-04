require "test_helper"

class LLM::CostTrackingDecoratorTest < ActiveSupport::TestCase
  def setup
    @client = Minitest::Mock.new
    def @client.model_name; "claude-3-sonnet"; end

    @decorator = LLM::CostTrackingDecorator.new(@client)
    @user = users(:teacher)
    @submission = student_submissions(:pending_submission)

    @response = {
      content: "Test response",
      metadata: {
        tokens: {
          prompt: 100,
          completion: 50,
          total: 150
        },
        cost: 0.00225
      }
    }

    @input_object = {
      prompt: "Test prompt",
      context: {
        request_type: "test",
        trackable: @submission,
        user: @user,
        metadata: { test: true }
      }
    }
  end

  test "passes the request to the original client" do
    # Setup
    @client.expect :execute_request, @response, [ @input_object ]

    # Exercise
    @decorator.execute_request(@input_object)

    # Verify
    @client.verify
  end

  test "creates a cost log record" do
    # Setup
    @client.expect :execute_request, @response, [ @input_object ]

    # Exercise
    assert_difference -> { LlmCostLog.count }, 1 do
      @decorator.execute_request(@input_object)
    end

    # Verify
    log = LlmCostLog.last
    assert_equal @user, log.user
    assert_equal @submission, log.trackable
    assert_equal "test", log.request_type
    assert_equal 100, log.prompt_tokens
    assert_equal 50, log.completion_tokens
    assert_equal 150, log.total_tokens
    assert_equal 0.00225, log.cost
    assert_equal "claude-3-sonnet", log.llm_model_name
  end

  test "returns the original response" do
    # Setup
    @client.expect :execute_request, @response, [ @input_object ]

    # Exercise
    result = @decorator.execute_request(@input_object)

    # Verify
    assert_equal @response, result
  end

  test "handles missing token information" do
    # Setup
    response_without_tokens = {
      content: "Test response",
      metadata: {}
    }
    @client.expect :execute_request, response_without_tokens, [ @input_object ]

    # Exercise
    assert_difference -> { LlmCostLog.count }, 1 do
      @decorator.execute_request(@input_object)
    end

    # Verify
    log = LlmCostLog.last
    assert_equal 0, log.prompt_tokens
    assert_equal 0, log.completion_tokens
    assert_equal 0, log.total_tokens
  end

  test "handles missing context" do
    # Setup
    input_without_context = { prompt: "Test prompt" }
    @client.expect :execute_request, @response, [ input_without_context ]

    # Exercise
    assert_difference -> { LlmCostLog.count }, 1 do
      @decorator.execute_request(input_without_context)
    end

    # Verify
    log = LlmCostLog.last
    assert_nil log.request_type
    assert_nil log.trackable
    assert_nil log.user
  end

  test "handles responses without metadata" do
    # Setup
    response_without_metadata = { content: "Test response" }
    @client.expect :execute_request, response_without_metadata, [ @input_object ]

    # Exercise & Verify
    assert_no_difference -> { LlmCostLog.count } do
      @decorator.execute_request(@input_object)
    end
  end

  test "delegates unknown methods to client" do
    # Setup
    @client.expect :some_method, "result", []

    # Exercise
    result = @decorator.some_method

    # Verify
    assert_equal "result", result
    @client.verify
  end

  test "responds to client methods" do
    # Define a method on the client that the decorator should respond to
    def @client.test_method; "test"; end

    # Exercise & Verify
    assert @decorator.respond_to?(:test_method)
    assert @decorator.respond_to?(:llm_model_name)
  end
end
