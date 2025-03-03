class GradingLogger
  def self.capture_parsing_attempt(strategy, response)
    context = {
      strategy: strategy.class.name,
      response_sample: response.to_s.truncate(100),
      timestamp: Time.now
    }

    Rails.logger.info("Attempting to parse response with #{strategy.class.name}", context)

    # Return a logging context that will be used by subsequent log calls
    context
  end

  def self.log_parsing_success(context, result)
    context[:success] = true
    context[:parsed_fields] = {
      feedback_length: result.feedback&.length,
      strengths_count: result.strengths&.size,
      opportunities_count: result.opportunities&.size,
      grade_present: result.overall_grade.present?,
      scores_present: result.scores.present?
    }

    Rails.logger.info("Successfully parsed response", context)
  end

  def self.log_parsing_failure(context, error)
    # Initialize context as an empty hash if nil
    context ||= {}

    context[:success] = false
    context[:error] = {
      message: error.message,
      backtrace: error.backtrace&.first(5)
    }

    Rails.logger.warn("Failed to parse response", context)
  end

  def self.log_final_result(strategies_attempted, final_strategy, success)
    context = {
      attempted_strategies: strategies_attempted,
      successful_strategy: final_strategy,
      success: success
    }

    if success
      Rails.logger.info("Response successfully parsed after #{strategies_attempted.size} attempts", context)
    else
      Rails.logger.error("All parsing strategies failed", context)
    end
  end

  # Log an error that occurred during the grading process
  # This method is designed to be very flexible with arguments to avoid compatibility issues
  #
  # @param args Any arguments - first one is treated as the error, second (optional) as the response
  # @return [nil]
  def self.log_grading_error(*args)
    # Default values
    error = StandardError.new("Unknown error")
    response = nil

    # Process arguments based on count
    case args.size
    when 0
      # Use defaults
    when 1
      # One argument - assume it's the error
      error = args[0].is_a?(Exception) ? args[0] : StandardError.new(args[0].to_s)
    else
      # Multiple arguments - first is error, second is response
      error = args[0].is_a?(Exception) ? args[0] : StandardError.new(args[0].to_s)
      response = args[1]
    end

    # Build context with error information
    context = {
      error_class: error.class.name,
      message: error.message,
      backtrace: error.backtrace&.first(10)
    }

    # Add response sample if provided
    context[:response_sample] = response.to_s.truncate(300) if response

    # Log the error
    Rails.logger.error("Error during grading process", context)
  end

  # Debug wrapper to help locate the source of the wrong number of arguments error
  def self.debug_error(*args)
    Rails.logger.error("DEBUG: GradingLogger called with #{args.size} arguments.")

    # Print the backtrace to see where this is being called from
    caller_locations.first(5).each_with_index do |location, index|
      Rails.logger.error("DEBUG: Caller #{index}: #{location}")
    end

    # Print argument details for debugging
    args.each_with_index do |arg, index|
      Rails.logger.error("DEBUG: Argument #{index} is a #{arg.class.name}: #{arg.inspect.truncate(100)}")
    end

    # Call the actual method so behavior doesn't change
    original_log_grading_error(*args)
  end

  # Alias the original method and replace it with our debug version
  class << self
    alias_method :original_log_grading_error, :log_grading_error
    alias_method :log_grading_error, :debug_error
  end

  # Logs a validation failure for a parsing strategy
  # @param context [Hash] The parsing context
  def self.log_validation_failure(context = {})
    # Initialize context as an empty hash if nil
    context ||= {}

    context[:success] = false
    context[:validation_errors] = "Validation failed"

    Rails.logger.warn("Response parsing validation failed", context)
  end
end
