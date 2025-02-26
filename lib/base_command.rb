# frozen_string_literal: true

# Base class for implementing the Command pattern in GradeBot
# Provides common functionality for executing commands, handling errors,
# and tracking command execution state.
#
# @example Implementing a custom command
#   class GreetCommand < BaseCommand
#     def initialize(name:)
#       super
#     end
#
#     private
#
#     def execute
#       @result = "Hello, #{name}!"
#     end
#   end
#
# @abstract Subclass and implement {#execute} to create a custom command
class BaseCommand
  # @return [Object] The result of the command execution
  # @return [nil] If the command hasn't been executed or failed
  attr_reader :result

  # @return [Array<String>] Collection of error messages from failed execution
  attr_reader :errors

  # Initialize a new command instance
  # @param args [Hash] Keyword arguments to be stored as instance variables
  def initialize(**args)
    @input_parameters = args
    @errors = []
    store_input_parameters
  end

  # Execute the command and return self for method chaining
  # @return [BaseCommand] self
  def call
    @result = execute
    self
  rescue StandardError => e
    handle_error(e)
    self
  end

  # Check if the command executed successfully
  # @return [Boolean] true if execution completed without errors and produced a result
  def success?
    errors.empty? && !result.nil?
  end

  # Check if the command failed
  # @return [Boolean] true if execution produced errors or no result
  def failure?
    !success?
  end

  private

  # Store input parameters as instance variables for subclass access
  def store_input_parameters
    @input_parameters.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  # Handle execution errors by storing the error message
  # @param error [StandardError] The error that occurred during execution
  def handle_error(error)
    @errors << error.message
  end

  # Implement command-specific logic in subclasses
  # @abstract
  # @raise [NotImplementedError] when called without subclass implementation
  def execute
    raise NotImplementedError,
          "#{self.class} must implement abstract method #execute"
  end
end
