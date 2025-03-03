# frozen_string_literal: true

# Helper module for managing LLM configuration in tests
# This helps ensure consistent configuration during testing and avoids parameter issues
module LLMConfigurationHelper
  # Reset all LLM configuration to a known test state
  # This provides a clean slate for each test
  def reset_llm_configuration
    # Stub the base Configuration class
    # This ensures tests don't rely on real API connections or keys
    stub_llm_enabled(true)
    stub_default_model_config
    stub_task_specific_configs
  end

  # Stub the enabled status of the LLM system
  # @param enabled [Boolean] Whether LLM features should be enabled in tests
  def stub_llm_enabled(enabled = true)
    LLM::Configuration.stubs(:enabled?).returns(enabled)
  end

  # Stub the default model configuration
  # @param config [Hash] The configuration to use, or nil for a standard test config
  def stub_default_model_config(config = nil)
    default_config = config || {
      provider: :test,
      model: "test-model",
      temperature: 0.5,
      max_tokens: 1000
    }

    LLM::Configuration.stubs(:default_model).returns(default_config)
  end

  # Stub specific task configurations
  # @param task [Symbol] The task to configure (e.g., :grade_assignment)
  # @param config [Hash] The configuration to use for this task
  def stub_task_config(task, config)
    LLM::Configuration.stubs(:model_for).with(task).returns(config)
  end

  # Configure all common task configurations used in the app
  def stub_task_specific_configs
    # Set up configuration for grading
    grading_config = {
      provider: :test,
      model: "test-grading-model",
      temperature: 0.7,
      max_tokens: 2000
    }

    stub_task_config(:grade_assignment, grading_config)
  end

  # Clean up all stubs when done with testing
  def unstub_all_llm_configuration
    LLM::Configuration.unstub(:enabled?)
    LLM::Configuration.unstub(:default_model)
    LLM::Configuration.unstub(:model_for)
  end

  # Utility method to mock a successful LLM response
  # @param content [String] The response content
  # @return [Hash] A properly formatted mock response
  def mock_llm_response(content)
    {
      content: content,
      metadata: {
        tokens: {
          prompt: 100,
          completion: 50,
          total: 150
        }
      }
    }
  end

  # Create a mock LLM client for testing
  # @param response [Hash] The response the mock client should return
  # @return [Object] A mock client object
  def mock_llm_client(response = nil)
    default_response = mock_llm_response('{"feedback": "Test feedback"}')
    client = mock("llm_client")
    client.stubs(:generate).returns(response || default_response)
    client
  end
end
