# frozen_string_literal: true

# Handles cleaning and sanitizing content for LLM prompts
class ContentCleaner
  MAX_LENGTH = 15_000

  def self.clean(content)
    Rails.logger.debug("ContentCleaner: Beginning content cleaning with content length: #{content&.length || 0}")

    return "" if content.nil?

    # Truncate long content
    if content.length > MAX_LENGTH
      Rails.logger.warn("Document content truncated from #{content.length} to #{MAX_LENGTH} characters")
      content = content[0...MAX_LENGTH]
    end

    # Replace tabs with spaces
    content = content.gsub("\t", "    ")

    # Normalize line endings
    content = content.gsub("\r\n", "\n").gsub("\r", "\n")

    # Remove control characters
    content = content.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, "")

    Rails.logger.debug("ContentCleaner: Content cleaning complete, final length: #{content.length}")

    content
  end
end
