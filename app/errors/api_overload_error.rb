# frozen_string_literal: true

# Custom error class for API overload/rate limiting errors
class ApiOverloadError < StandardError
  attr_reader :retry_after, :original_error

  def initialize(message, retry_after: nil, original_error: nil)
    @retry_after = retry_after
    @original_error = original_error
    super(message)
  end

  def retryable?
    true
  end
end
