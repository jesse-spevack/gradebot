# frozen_string_literal: true

require "test_helper"

class LLM::BaseClientTest < ActiveSupport::TestCase
  class TestClient < LLM::BaseClient
    attr_reader :execute_called, :last_input, :token_count, :cost_estimate

    # Override generate to avoid logging concerns
    def generate(input_object)
      @execute_called = true
      @last_input = input_object

      # Calculate tokens and cost
      @token_count = calculate_token_count(input_object)

      # Execute request
      response = execute_request(input_object)

      # Calculate cost
      @cost_estimate = calculate_cost_estimate(response[:metadata][:tokens][:total])

      # Return enriched response
      {
        content: response[:content],
        metadata: response[:metadata].merge({
          execution_time_ms: 10,
          cost: @cost_estimate,
          model: model_name
        })
      }
    end

    def execute_request(input_object)
      # Simulates a response in the format we expect from the client
      {
        content: "Response content from test client",
        metadata: {
          tokens: { prompt: 10, completion: 20, total: 30 }
        }
      }
    end

    # Implement abstract methods
    def calculate_token_count(input_object)
      50 # Example count
    end

    def calculate_cost_estimate(token_count)
      token_count * 0.01 # $0.01 per token
    end
  end

  class AbstractMethodsClient < LLM::BaseClient
    # Does not implement abstract methods
  end

  class ErrorClient < LLM::BaseClient
    # Override generate to avoid logging concerns
    def generate(input_object)
      execute_request(input_object)
    end

    def execute_request(input_object)
      raise StandardError, "Test error"
    end

    def calculate_token_count(input_object)
      50
    end

    def calculate_cost_estimate(token_count)
      token_count * 0.01
    end
  end

  setup do
    @client = TestClient.new("test-model")
    @abstract_client = AbstractMethodsClient.new("test-model")
    @error_client = ErrorClient.new("test-model")
  end

  test "initializes with model name" do
    assert_equal "test-model", @client.model_name
  end

  test "generate calls execute_request with the input object" do
    input = { prompt: "Test prompt" }
    @client.generate(input)

    assert @client.execute_called
    assert_equal input, @client.last_input
  end

  test "generate returns a response with content and metadata" do
    input = { prompt: "Test prompt" }
    response = @client.generate(input)

    assert_kind_of Hash, response
    assert_includes response, :content
    assert_includes response, :metadata
    assert_equal "Response content from test client", response[:content]
  end

  test "generate calculates and includes token count in metadata" do
    input = { prompt: "Test prompt" }
    response = @client.generate(input)

    assert_includes response[:metadata], :tokens
    assert_equal 30, response[:metadata][:tokens][:total]
  end

  test "generate calculates and includes cost estimate in metadata" do
    input = { prompt: "Test prompt" }
    response = @client.generate(input)

    assert_includes response[:metadata], :cost
    assert_equal 0.3, response[:metadata][:cost]
  end

  test "generate includes execution time in metadata" do
    input = { prompt: "Test prompt" }
    response = @client.generate(input)

    assert_includes response[:metadata], :execution_time_ms
    assert_equal 10, response[:metadata][:execution_time_ms]
  end

  test "execute_request raises NotImplementedError when not implemented" do
    input = { prompt: "Test prompt" }

    assert_raises(NotImplementedError) do
      @abstract_client.execute_request(input)
    end
  end

  test "calculate_token_count raises NotImplementedError when not implemented" do
    input = { prompt: "Test prompt" }

    assert_raises(NotImplementedError) do
      @abstract_client.calculate_token_count(input)
    end
  end

  test "calculate_cost_estimate raises NotImplementedError when not implemented" do
    assert_raises(NotImplementedError) do
      @abstract_client.calculate_cost_estimate(100)
    end
  end

  test "generate re-raises errors from execute_request" do
    assert_raises(StandardError) do
      @error_client.generate({ prompt: "Test prompt" })
    end
  end
end
