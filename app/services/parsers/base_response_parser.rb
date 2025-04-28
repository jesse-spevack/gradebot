# frozen_string_literal: true

module Parsers
  # Base class for all response parsers
  class BaseResponseParser
    # Parse a response from an LLM
    # @param response [String] The raw response from the LLM
    # @return [Object] The parsed result
    def parse(response)
      raise NotImplementedError, "Subclasses must implement #parse"
    end

    private

    # Convert a string to JSON, with error handling
    # @param json_string [String] The JSON string to parse
    # @return [Hash] The parsed JSON
    def parse_json(json_string)
      JSON.parse(json_string)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON response: #{e.message}")
      Rails.logger.error("JSON string: #{json_string}")
      raise ParseError, "Failed to parse JSON response: #{e.message}"
    end
  end

  # Error class for parsing errors
  class ParseError < StandardError; end
end
