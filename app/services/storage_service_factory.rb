# frozen_string_literal: true

# Factory for creating storage service instances
class StorageServiceFactory
  # Create a storage service instance from a class or class name
  # @param storage_class [Class] The storage service class
  # @return [Object] An instance of the storage service class
  def self.create(storage_class)
    # If storage_class is a string, convert to constant
    if storage_class.is_a?(String)
      begin
        storage_class = storage_class.constantize
      rescue NameError
        Rails.logger.error("Could not instantiate storage class: #{storage_class}")
        raise ArgumentError, "Unknown storage service: #{storage_class}"
      end
    end

    storage_class.new
  end
end
