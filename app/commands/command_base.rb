# frozen_string_literal: true

# Base command class for the Command pattern
# Provides common functionality for command execution and result tracking
#
# @example Using a command
#   MyCommand.call(argument_1: 1, argument_2: 'y')
#
# @abstract Subclass and implement {#execute} to create a custom command
class CommandBase
    # @return [Object] The result of the command execution
    attr_reader :result

    # @return [Array<String>] Collection of error messages from failed execution
    attr_reader :errors

    # Class method to instantiate and call a command
    # @param args [Hash] Keyword arguments to pass to the command
    # @return [Base] Command instance after execution
    def self.call(*args, **kwargs)
      if args.any?
        raise ArgumentError, "Cannot be called with positional arguments"
      else
        new(**kwargs).call
      end
    end

    # Initialize a new command instance
    # @param args [Hash] Keyword arguments to be stored as instance variables
    def initialize(**args)
      @errors = []
      store_input_parameters(args)
    end

    # Execute the command and return self for method chaining
    # @return [Base] self
    def call
      @result = execute
      self
    rescue StandardError => e
      handle_error(e)
      self
    end

    # Check if the command executed successfully
    # @return [Boolean] true if execution completed without errors
    def success?
      errors.empty? && !result.nil?
    end

    # Check if the command failed
    # @return [Boolean] true if execution produced errors or no result
    def failure?
      !success?
    end

    private

    # Store input parameters as instance variables
    # @param params [Hash] Parameters to store as instance variables
    def store_input_parameters(params)
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
        # Define reader methods for the instance variables
        self.class.class_eval { attr_reader key } unless respond_to?(key)
      end
    end

    # Handle execution errors by storing the error message
    # @param error [StandardError] The error that occurred during execution
    def handle_error(error)
      @errors << error.message
    end

    # Implement command-specific logic in subclasses
    # @abstract
    # @return [Object] Result of the command execution
    def execute
      raise NotImplementedError,
            "#{self.class} must implement abstract method #execute"
    end
end
