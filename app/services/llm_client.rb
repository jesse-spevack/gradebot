# frozen_string_literal: true

# Handles communication with LLM services
class LLMClient
  def initialize(config)
    @config = config
  end

  def generate(prompt)
    Rails.logger.info("Calling LLM with model: #{@config[:model]}")

    # Get the LLM client
    llm_client = LLM::ClientFactory.create(@config[:model])

    # Generate the response
    response = llm_client.generate({ prompt: prompt })

    # Log the raw response for debugging
    Rails.logger.debug("RAW LLM RESPONSE BEGIN")
    Rails.logger.debug(response[:content].to_s)
    Rails.logger.debug("RAW LLM RESPONSE END")

    response
  end
end
