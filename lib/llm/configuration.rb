# frozen_string_literal: true

module LLM
  class Configuration
    # Define supported models for each provider
    MODELS = {
      anthropic: {
        default: {
          provider: :anthropic,
          model: "claude-3-5-sonnet",
          temperature: 0.7
        }
      },
      openai: {
        default: {
          provider: :openAI,
          model: "gpt-4-turbo",
          temperature: 0.7
        }
      },
      google: {
        default: {
          provider: :google,
          model: "gemini-pro",
          temperature: 0.7
        }
      }
    }.freeze

    # Define task-specific configurations
    TASK_CONFIGURATIONS = {
      grade_assignment: {
        provider: :anthropic,
        model: "claude-3-5-sonnet",
        temperature: 0.7,
        max_tokens: 4000
      }
    }.freeze

    # Check if LLM features are enabled
    def self.enabled?
      FeatureFlagService.new.enabled?("llm_enabled")
    end

    # Get configuration for a specific task
    def self.model_for(task)
      config = TASK_CONFIGURATIONS[task]
      raise ArgumentError, "Unsupported task type: #{task}" unless config

      config
    end

    # Get the default model configuration
    def self.default_model
      MODELS[:anthropic][:default]
    end
  end
end
