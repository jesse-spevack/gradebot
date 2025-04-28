# frozen_string_literal: true

# Factory for creating status manager instances
class StatusManagerFactory
  # Create a status manager instance from a class or class name
  # @param status_manager_class [Class, nil] The status manager class or class name
  def self.create(status_manager_class)
    return nil unless status_manager_class

    # If status_manager_class is a string, convert to constant
    if status_manager_class.is_a?(String)
      begin
        status_manager_class = status_manager_class.constantize
      rescue NameError
        Rails.logger.error("Could not instantiate status manager class: #{status_manager_class}")
        raise ArgumentError, "Unknown status manager: #{status_manager_class}"
      end
    end

    status_manager_class.new
  end
end
