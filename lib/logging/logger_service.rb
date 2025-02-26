# frozen_string_literal: true

module Logging
  # Service for structured logging with context and operation tracking.
  # Provides a consistent interface for logging with structured data,
  # context preservation between calls, and operation timing.
  #
  # @example Basic logging
  #   logger = LoggerService.new(user_id: 123)
  #   logger.info("User logged in")
  #
  # @example Operation tracking
  #   logger.operation("Complex task") do
  #     # ... perform task ...
  #   end
  #
  # @example Context merging
  #   logger.with_context(session_id: "abc") do
  #     logger.info("Action in session")
  #   end
  #
  # @example Error logging
  #   begin
  #     # ... code that might raise an error ...
  #   rescue => error
  #     logger.error("Operation failed", error: error)
  #   end
  class LoggerService
    # Log levels in order of increasing severity
    LEVELS = %i[debug info warn error fatal].freeze

    # @return [Hash] The current logging context
    attr_reader :context

    # Initialize a new logger with context
    # @param context [Hash] Initial context for all log entries
    def initialize(context = {})
      @context = context.dup.freeze
      @log_device = Rails.logger
      @operation_stack = []
    end

    # Execute a block with additional context
    # @param additional_context [Hash] Context to merge for the duration of the block
    # @yield Block to execute with merged context
    # @return [Object] Result of the block
    def with_context(additional_context)
      return yield if additional_context.empty?

      original_context = @context
      @context = @context.merge(additional_context).freeze
      yield
    ensure
      @context = original_context
    end

    # Track and time an operation
    # @param operation_name [String] Name of the operation
    # @param context [Hash] Additional context for this operation
    # @yield Block representing the operation
    # @return [Object] Result of the operation block
    def operation(operation_name, context = {})
      start_time = Time.current
      @operation_stack.push(operation_name)
      result = with_context(context) { yield }
      duration = ((Time.current - start_time) * 1000).round
      log_operation(operation_name, duration)
      result
    ensure
      @operation_stack.pop
    end

    # Generate logging methods for each level (debug, info, warn, error, fatal)
    LEVELS.each do |level|
      define_method(level) do |message, **fields|
        log(level, message, **fields)
      end
    end

    private

    # Core logging method
    # @param level [Symbol] Log level (:debug, :info, etc.)
    # @param message [String] Log message
    # @param fields [Hash] Additional fields to log
    def log(level, message, **fields)
      entry = build_log_entry(message, fields)
      write_log_entry(level, entry)
    end

    # Build a structured log entry
    # @param message [String] Log message
    # @param fields [Hash] Additional fields to log
    # @return [Hash] Formatted log entry
    def build_log_entry(message, fields)
      entry = {
        timestamp: Time.current.iso8601(3),
        message: message,
        operation: @operation_stack.last,
        context: @context
      }

      # Handle error objects specially
      if fields[:error].is_a?(Exception)
        entry[:error] = fields[:error].message
        fields = fields.except(:error)
      end

      entry.merge(fields)
    end

    # Write entry to the log device
    # @param level [Symbol] Log level (:debug, :info, etc.)
    # @param entry [Hash] Structured log entry
    def write_log_entry(level, entry)
      @log_device.public_send(level, entry)
    end

    # Log an operation completion
    # @param operation_name [String] Name of the operation
    # @param duration [Integer] Duration of the operation in milliseconds
    def log_operation(operation_name, duration)
      info(operation_name, duration: duration)
    end
  end
end
