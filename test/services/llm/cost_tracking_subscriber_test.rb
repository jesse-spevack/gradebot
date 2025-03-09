require "test_helper"

class LLM::CostTrackingSubscriberTest < ActiveSupport::TestCase
  setup do
    # Clear any existing subscribers
    LLM::EventSystem::Publisher.clear!

    # Create a new subscriber for testing
    @subscriber = LLM::CostTrackingSubscriber.new

    # Mock the CostTracking module
    @original_calculate_cost = LLM::CostTracking.method(:calculate_cost)
    @original_record = LLM::CostTracking.method(:record)

    # Track calls to CostTracking methods - make it class variable so it's accessible in method redefinitions
    @@cost_tracking_calls = []

    LLM::CostTracking.define_singleton_method(:calculate_cost) do |model, prompt, completion|
      @@cost_tracking_calls << {
        method: :calculate_cost,
        model: model,
        prompt: prompt,
        completion: completion
      }
      0.05 # Return a fixed cost for testing
    end

    LLM::CostTracking.define_singleton_method(:record) do |cost_data, context|
      @@cost_tracking_calls << {
        method: :record,
        cost_data: cost_data,
        context: context
      }
      true # Return success
    end
  end

  teardown do
    # Restore original methods
    LLM::CostTracking.define_singleton_method(:calculate_cost, @original_calculate_cost)
    LLM::CostTracking.define_singleton_method(:record, @original_record)
  end

  test "subscriber registers for request_completed event" do
    assert_includes LLM::EventSystem::Publisher.subscribers[LLM::EventSystem::EVENTS[:request_completed]], @subscriber
  end

  test "handles request_completed event with token information" do
    # Reset tracking calls
    @@cost_tracking_calls = []

    # Create a mock request and response
    llm_request = mock("LLMRequest")
    llm_request.stubs(:llm_model_name).returns("claude-3-sonnet")

    response = {
      content: "Test response",
      metadata: {
        tokens: {
          prompt: 100,
          completion: 50,
          total: 150
        }
      }
    }

    context = { request_id: "test-123", user_id: 1 }

    # Publish the event
    LLM::EventSystem::Publisher.publish(
      LLM::EventSystem::EVENTS[:request_completed],
      {
        request: llm_request,
        response: response,
        context: context
      }
    )

    # Verify CostTracking methods were called
    calculate_call = @@cost_tracking_calls.find { |call| call[:method] == :calculate_cost }
    assert calculate_call, "calculate_cost should have been called"
    assert_equal "claude-3-sonnet", calculate_call[:model]
    assert_equal 100, calculate_call[:prompt]
    assert_equal 50, calculate_call[:completion]

    record_call = @@cost_tracking_calls.find { |call| call[:method] == :record }
    assert record_call, "record should have been called"
    assert_equal "claude-3-sonnet", record_call[:cost_data][:llm_model_name]
    assert_equal 100, record_call[:cost_data][:prompt_tokens]
    assert_equal 50, record_call[:cost_data][:completion_tokens]
    assert_equal 150, record_call[:cost_data][:total_tokens]
    assert_equal 0.05, record_call[:cost_data][:cost]
    assert_equal "test-123", record_call[:cost_data][:request_id]
    assert_equal context, record_call[:context]
  end

  test "ignores request_completed event without token information" do
    # Reset tracking calls
    @@cost_tracking_calls = []

    # Create a mock request and response without token info
    llm_request = mock("LLMRequest")
    llm_request.stubs(:llm_model_name).returns("claude-3-sonnet")

    response = { content: "Test response" }
    context = { request_id: "test-123" }

    # Publish the event
    LLM::EventSystem::Publisher.publish(
      LLM::EventSystem::EVENTS[:request_completed],
      {
        request: llm_request,
        response: response,
        context: context
      }
    )

    # Verify no CostTracking methods were called
    assert_empty @@cost_tracking_calls, "No cost tracking methods should have been called"
  end
end
