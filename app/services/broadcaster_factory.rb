# frozen_string_literal: true

# Factory for creating broadcaster instances
class BroadcasterFactory
  # Create a broadcaster instance from a class or class name
  # @param broadcaster_class [Class, nil] The broadcaster class or class name
  def self.create(broadcaster_class)
    return nil unless broadcaster_class

    # If broadcaster_class is a string, convert to constant
    if broadcaster_class.is_a?(String)
      begin
        broadcaster_class = broadcaster_class.constantize
      rescue NameError
        Rails.logger.error("Could not instantiate broadcaster class: #{broadcaster_class}")
        raise ArgumentError, "Unknown broadcaster: #{broadcaster_class}"
      end
    end

    broadcaster_class.new
  end
end
