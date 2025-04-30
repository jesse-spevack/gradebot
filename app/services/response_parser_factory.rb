# frozen_string_literal: true

# Factory for creating response parser instances
class ResponseParserFactory
  # Create a response parser instance from a class or class name
  # @param parser_class [Class] The parser class or class name
  # @return [Object] An instance of the parser class
  def self.create(parser_class)
    # If parser_class is a string, convert to constant
    if parser_class.is_a?(String)
      begin
        parser_class = parser_class.constantize
      rescue NameError
        Rails.logger.error("Could not instantiate parser class: #{parser_class}")
        raise ArgumentError, "Unknown response parser: #{parser_class}"
      end
    end

    parser_class.new
  end
end
