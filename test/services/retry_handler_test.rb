# frozen_string_literal: true

require "test_helper"

class RetryHandlerTest < ActiveSupport::TestCase
  test "executes block successfully without retries" do
    # No need to stub sleep since it won't be called
    result = RetryHandler.with_retry do
      "success"
    end
    assert_equal "success", result
  end
end
