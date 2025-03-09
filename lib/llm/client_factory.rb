# frozen_string_literal: true

require_relative "errors"

module LLM
  # Factory class for creating LLM clients
  #
  # This factory creates and returns the appropriate Claude client for processing LLM requests.
  # Currently, the application only uses Claude models.
  #
  # @example Create a client
  #   client = LLM::ClientFactory.create
  #   # Returns an instance of LLM::Anthropic::Client
  #
  class ClientFactory
    # Create a client instance for processing LLM requests
    #
    # @return [LLM::Anthropic::Client] an instance of the Anthropic client
    def self.create
      # Require the client file
      require_relative "anthropic/client"

      # Instantiate the client
      LLM::Anthropic::Client.new
    end

    # This method is kept for backward compatibility
    # It ignores the model_name parameter and always returns an Anthropic client
    #
    # @param model_name [String] Ignored parameter (kept for backward compatibility)
    # @return [LLM::Anthropic::Client] an instance of the Anthropic client
    def self.create_with_model(model_name)
      create
    end
  end
end
