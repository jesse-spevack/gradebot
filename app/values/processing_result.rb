# frozen_string_literal: true

# Value object representing the result of a processing task
class ProcessingResult
  attr_reader :success, :data, :error

  # Initialize a new processing result
  # @param success [Boolean] Whether the processing was successful
  # @param data [Hash, nil] The processed data (nil if processing failed)
  # @param error [String, nil] Error message if processing failed (nil if successful)
  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end

  # Check if the processing was successful
  # @return [Boolean] True if successful, false otherwise
  def success?
    @success
  end

  # Check if the processing failed
  # @return [Boolean] True if failed, false otherwise
  def failure?
    !@success
  end
end
