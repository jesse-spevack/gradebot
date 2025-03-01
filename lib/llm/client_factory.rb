# frozen_string_literal: true

require_relative "errors"

module LLM
  # Factory class for creating LLM clients based on model names
  #
  # This factory creates appropriate client instances based on model name prefixes:
  # - Models starting with "gpt" use the OpenAI client
  # - Models starting with "claude" use the Anthropic client
  # - Models starting with "gemini" use the Google client
  #
  # @example Create a client for a specific model
  #   client = LLM::ClientFactory.create("claude-3-5-sonnet")
  #   # Returns an instance of LLM::Anthropic::Client
  #
  # @example Create a client using configuration
  #   config = LLM::Configuration.model_for(:grade_assignment)
  #   client = LLM::ClientFactory.create(config[:model])
  #
  class ClientFactory
    # Maps model name prefixes to their respective client classes
    MODEL_PREFIXES = {
      "gpt" => "LLM::OpenAI::Client",
      "claude" => "LLM::Anthropic::Client",
      "gemini" => "LLM::Google::Client"
    }.freeze

    # Create a client instance for the specified model
    #
    # @param model_name [String] the name of the model to use
    # @return [Object] an instance of the appropriate client for the model
    # @raise [LLM::Errors::UnsupportedModelError] if the model prefix is not recognized
    def self.create(model_name)
      client_class = client_class_for(model_name)

      # Require the client file if it hasn't been loaded yet
      require_client_file(client_class)

      # Instantiate the client with the model name
      client_class.constantize.new(model_name)
    end

    private

    # Determine the appropriate client class for the given model name
    #
    # @param model_name [String] the name of the model
    # @return [String] the class name of the appropriate client
    # @raise [LLM::Errors::UnsupportedModelError] if the model prefix is not recognized
    def self.client_class_for(model_name)
      prefix = MODEL_PREFIXES.keys.find { |prefix| model_name.to_s.start_with?(prefix) }

      unless prefix
        raise LLM::Errors::UnsupportedModelError, model_name
      end

      MODEL_PREFIXES[prefix]
    end

    # Require the client file for the given client class
    #
    # @param client_class_name [String] the full name of the client class
    def self.require_client_file(client_class_name)
      # Extract the path from the class name
      # E.g., "LLM::OpenAI::Client" -> "llm/open_AI/client"
      path = client_class_name.underscore

      # Require the file if it exists
      begin
        require path
      rescue LoadError
        # The file might already be loaded or not exist yet
        # This is expected in some cases, so we'll continue
      end
    end
  end
end
