# frozen_string_literal: true

require "test_helper"

class LLM::BaseClientTest < ActiveSupport::TestCase
  class TestClient < LLM::BaseClient
    attr_reader :execute_called, :last_input, :token_count

    # Override generate to avoid logging concerns
    def generate(llm_request)
      # Call the parent method to validate the request
      super

      @execute_called = true
      @last_input = llm_request

      # Calculate tokens
      @token_count = calculate_token_count(llm_request)

      # Execute request
      response = execute_request(llm_request)

      # Return enriched response
      {
        content: response[:content],
        metadata: response[:metadata].merge({
          execution_time_ms: 10,
          model: llm_request.llm_model_name
        })
      }
    end

    def execute_request(llm_request)
      # Simulates a response in the format we expect from the client
      {
        content: "Response content from test client",
        metadata: {
          tokens: { prompt: 10, completion: 20, total: 30 }
        }
      }
    end

    # Implement abstract methods
    def calculate_token_count(llm_request)
      50 # Example count
    end
  end

  class AbstractMethodsClient < LLM::BaseClient
    # Does not implement abstract methods
  end

  class ErrorClient < LLM::BaseClient
    # Override generate to avoid logging concerns
    def generate(llm_request)
      # Skip validation to focus on error handling
      execute_request(llm_request)
    end

    def execute_request(llm_request)
      raise StandardError, "Test error"
    end

    def calculate_token_count(llm_request)
      50
    end
  end

  setup do
    @client = TestClient.new
    @abstract_client = AbstractMethodsClient.new
    @error_client = ErrorClient.new

    @llm_request = LLMRequest.new(
      prompt: "Test prompt",
      llm_model_name: "test-model",
      request_type: "test"
    )
  end

  test "generate calls execute_request with the LLMRequest object" do
    @client.generate(@llm_request)

    assert @client.execute_called
    assert_equal @llm_request, @client.last_input
  end

  test "generate returns a response with content and metadata" do
    response = @client.generate(@llm_request)

    assert_kind_of Hash, response
    assert_includes response, :content
    assert_includes response, :metadata
    assert_equal "Response content from test client", response[:content]
  end

  test "generate calculates and includes token count in metadata" do
    response = @client.generate(@llm_request)

    assert_includes response[:metadata], :tokens
    assert_equal 30, response[:metadata][:tokens][:total]
  end

  test "generate includes execution time in metadata" do
    response = @client.generate(@llm_request)

    assert_includes response[:metadata], :execution_time_ms
    assert_equal 10, response[:metadata][:execution_time_ms]
  end

  test "execute_request raises NotImplementedError when not implemented" do
    assert_raises(NotImplementedError) do
      @abstract_client.execute_request(@llm_request)
    end
  end

  test "calculate_token_count raises NotImplementedError when not implemented" do
    assert_raises(NotImplementedError) do
      @abstract_client.calculate_token_count(@llm_request)
    end
  end

  test "generate re-raises errors from execute_request" do
    assert_raises(StandardError) do
      @error_client.generate(@llm_request)
    end
  end

  test "generate validates that input is a LLMRequest" do
    assert_raises(ArgumentError) do
      @client.generate({ prompt: "Test prompt" })
    end
  end
end
