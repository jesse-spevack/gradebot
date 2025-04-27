# frozen_string_literal: true

require_relative "anthropic/client"
require_relative "gemini/client"
require_relative "errors"

module LLM
  # Factory for creating LLM client instances.
  # Determines the appropriate client based on the requested model.
  class ClientFactory
    # Creates an instance of the appropriate LLM client.
    #
    # @param model_name [String] The name of the LLM model requested (e.g., "claude-3-haiku-20240307", "gemini-1.5-flash-latest").
    # @param options [Hash] Optional configuration for the client.
    # @return [LLM::BaseClient] An instance of the appropriate client.
    # @raise [LLM::Errors::UnsupportedModelError] If the model family is not recognized.
    def self.create(model_name, options = {})
      # TODO: Add more robust model family detection if needed
      if model_name.nil? || model_name.strip.empty?
        raise LLM::Errors::UnsupportedModelError, "Model name cannot be blank."
      end

      if model_name.start_with?("claude-")
        Rails.logger.debug { "Creating Anthropic client for model: #{model_name}" }
        LLM::Anthropic::Client.new(options)
      elsif model_name.start_with?("gemini-")
        Rails.logger.debug { "Creating Gemini client for model: #{model_name}" }
        LLM::Gemini::Client.new(options)
      else
        Rails.logger.error { "Unsupported LLM model family for model: #{model_name}" }
        raise LLM::Errors::UnsupportedModelError, "Unsupported LLM model family for '#{model_name}'. Supported families start with 'claude-' or 'gemini-'."
      end
    end
  end
end
