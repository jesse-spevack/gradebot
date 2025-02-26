require "test_helper"

module Logging
  class LoggerServiceTest < ActiveSupport::TestCase
    include LoggingHelper
    def setup
      super  # This is crucial!
      @context = { user_id: 123, request_id: "abc-123" }
      @logger = LoggerService.new(@context)
    end

    def test_initialization_with_context
      assert_equal @context, @logger.context
    end

    def test_basic_logging_methods
      message = "Test message"
      @logger.info(message)
      assert_logged(message: message)
    end

    def test_context_preservation_between_calls
      @logger.info("First message")
      @logger.warn("Second message")
      assert_equal @context, @logger.context, "Context should remain unchanged between logging calls"
    end

    def test_operation_tracking
      operation_result = @logger.operation("Complex task") do
        "operation result"
      end

      assert_equal "operation result", operation_result, "Operation should return the block's result"
    end

    def test_operation_timing
      freeze_time do
        @logger.operation("Timed task") do
          travel 2.seconds
        end

        assert_logged(message: "Timed task", duration: 2000)
      end
    end

    def test_nested_operations
      @logger.operation("Outer task") do
        @logger.operation("Inner task") do
          "inner result"
        end
      end

      assert_logged(message: "Outer task", operation: "Outer task")
    end

    def test_error_logging
      error = StandardError.new("Test error")
      @logger.error("Error occurred", error: error)

      assert_logged(message: "Error occurred", error: "Test error")
    end

    def test_context_merging
      @logger.with_context(session_id: "xyz") do
        @logger.info("In context")
        assert_logged(message: "In context", context: @context.merge(session_id: "xyz"))
      end

      @logger.info("After context")
      assert_logged(message: "After context", context: @context)
    end
  end
end
