# frozen_string_literal: true

# Encapsulates all configuration and context for a specific LLM processing task
class ProcessingTask
  attr_reader :processable, :process_type, :user, :configuration, :context
  attr_accessor :started_at, :completed_at, :error_message
  attr_reader :metrics

  VALID_PROCESS_TYPES = [
    "generate_rubric",
    "grade_student_work",
    "generate_summary_feedback"
  ].freeze

  # Initialize a new processing task
  # @param processable [Object] The object being processed (StudentWork, Rubric, etc.)
  # @param process_type [String] The type of processing (e.g., "generate_rubric", "grade_student_work")
  # @param user [User] The user initiating the processing
  # @param configuration [OpenStruct] Configuration options for the processing
  # @param context [Hash] Additional context for the processing
  def initialize(processable:, process_type:, user: nil, configuration:, context: {})
    @processable = processable
    @process_type = process_type
    @user = user
    @configuration = configuration.is_a?(OpenStruct) ? configuration : OpenStruct.new(configuration)
    @context = context.with_indifferent_access
    @metrics = {}.with_indifferent_access
    validate!
  end

  # Get the prompt template to use
  # @return [String] The prompt template name
  def prompt_template
    configuration.prompt_template
  end

  # Get the response parser to use
  # @return [String] The response parser class
  def response_parser
    configuration.response_parser
  end

  # Get the storage service to use
  # @return [String] The storage service class
  def storage_service
    configuration.storage_service
  end

  # Get the broadcaster to use
  # @return [String, nil] The broadcaster class
  def broadcaster
    configuration.broadcaster
  end

  # Get the status manager to use
  # @return [String, nil] The status manager class
  def status_manager
    configuration.status_manager
  end

  # Get the model name to use
  # @return [String] The LLM model name
  def model_name
    configuration.model
  end

  # Record when processing starts
  def mark_started
    @started_at = Time.current
  end

  # Record when processing completes
  def mark_completed
    @completed_at = Time.current
  end

  # Calculate processing time in milliseconds
  # @return [Integer] The processing time in milliseconds
  def processing_time_ms
    return 0 unless started_at && completed_at
    ((completed_at - started_at) * 1000).to_i
  end

  # Record a metric
  # @param key [Symbol, String] The metric name
  # @param value [Object] The metric value
  def record_metric(key, value)
    # Ensure we're using string keys for consistency
    @metrics[key.to_s] = value
  end

  # Check if processing has started
  # @return [Boolean] True if started, false otherwise
  def started?
    !started_at.nil?
  end

  # Check if processing has completed
  # @return [Boolean] True if completed, false otherwise
  def completed?
    !completed_at.nil?
  end

  # Get metadata about the processing task including metrics
  # @return [Hash] The metadata
  def metadata
    base_metadata = {
      process_type: process_type,
      model_name: model_name,
      started_at: started_at,
      completed_at: completed_at,
      processing_time_ms: processing_time_ms
    }

    # Convert all keys to symbols for consistency when merging
    metrics_with_symbol_keys = {}
    @metrics.each do |key, value|
      metrics_with_symbol_keys[key.to_sym] = value
    end

    # Merge the metrics with the base metadata
    base_metadata.merge(metrics_with_symbol_keys)
  end

  private

  # Validate that required attributes are present
  def validate!
    raise ArgumentError, "Processable is required" unless processable
    raise ArgumentError, "Process type is required" unless process_type
    raise ArgumentError, "Invalid process type: #{process_type}" unless VALID_PROCESS_TYPES.include?(process_type)
    raise ArgumentError, "Configuration is required" unless configuration
    raise ArgumentError, "Prompt template is required" unless prompt_template
    raise ArgumentError, "Response parser is required" unless response_parser
    raise ArgumentError, "Storage service is required" unless storage_service
  end
end
