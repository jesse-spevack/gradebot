# frozen_string_literal: true

module LLM
  # Custom error raised when an unsupported model is requested
  class UnsupportedModelError < StandardError
    def initialize(model_name)
      super("Unsupported model: #{model_name}. No client available for this model type.")
    end
  end
end
