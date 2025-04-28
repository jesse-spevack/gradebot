# frozen_string_literal: true

require "test_helper"

class ProcessingResultTest < ActiveSupport::TestCase
  test "should initialize with success true" do
    # Setup
    data = { overall_grade: 85, feedback: "Good work" }

    # Exercise
    result = ProcessingResult.new(success: true, data: data)

    # Verify
    assert result.success?
    assert_not result.failure?
    assert_equal data, result.data
    assert_nil result.error
  end

  test "should initialize with success false" do
    # Setup
    error = "Something went wrong"

    # Exercise
    result = ProcessingResult.new(success: false, error: error)

    # Verify
    assert_not result.success?
    assert result.failure?
    assert_nil result.data
    assert_equal error, result.error
  end

  test "success? should return true for successful results" do
    # Exercise
    result = ProcessingResult.new(success: true)

    # Verify
    assert result.success?
  end

  test "failure? should return true for failed results" do
    # Exercise
    result = ProcessingResult.new(success: false)

    # Verify
    assert result.failure?
  end
end
