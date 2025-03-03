# frozen_string_literal: true

# Handles building prompts for different types of LLM requests
class PromptBuilder
  def self.build(type, params)
    begin
      PromptTemplate.render(type, params)
    rescue => e
      Rails.logger.error("Error building prompt: #{e.message}")
      raise e
    end
  end
end
