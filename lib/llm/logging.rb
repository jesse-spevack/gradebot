# frozen_string_literal: true

require_relative "../logging/logger_service"

module LLM
  # Logging service for LLM operations
  #
  # Provides standardized logging for LLM client operations,
  # including request tracking, errors, and performance metrics.
  # Uses the application's LoggerService for consistent structured logging.
  #
  # @example Log an informational message
  #   LLM::Logging.info("Processing request with model: claude-3-5-sonnet")
  #
  # @example Log an error with context
  #   LLM::Logging.error("API request failed", error: error, model: "gpt-4")
  #
  module Logging
    # Create a logger service instance for LLM operations
    #
    # @param additional_context [Hash] additional context to include with the logger
    # @return [Logging::LoggerService] a configured logger service instance
    def self.logger(additional_context = {})
      @base_context ||= { component: "llm" }
      ::Logging::LoggerService.new(@base_context.merge(additional_context))
    end

    # Log an informational message
    #
    # @param message [String] the message to log
    # @param context [Hash] additional context to include in the log
    def self.info(message, context = {})
      logger(context).info(message)
    end

    # Log an error message
    #
    # @param message [String] the error message to log
    # @param context [Hash] additional context to include in the log
    def self.error(message, context = {})
      logger(context).error(message)
    end

    # Log a debug message
    #
    # @param message [String] the debug message to log
    # @param context [Hash] additional context to include in the log
    def self.debug(message, context = {})
      logger(context).debug(message)
    end

    # Execute and log an LLM operation
    #
    # @param operation_name [String] the name of the operation
    # @param context [Hash] additional context for logging
    # @yield the operation to execute and log
    # @return [Object] the result of the operation
    def self.operation(operation_name, context = {})
      # Get a logger with base context
      log_service = logger

      # Use the operation method to track and log the operation
      # Pass the context directly to the operation method
      log_service.operation(operation_name, context) { yield }
    end
  end
end
