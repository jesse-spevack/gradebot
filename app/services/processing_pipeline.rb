# frozen_string_literal: true

# Orchestrates the LLM processing workflow for a ProcessingTask
class ProcessingPipeline
  # Initialize with a processing task
  # @param task [ProcessingTask] The task to process
  def initialize(task)
    @task = task
    @logger = Rails.logger
  end

  # Execute the processing pipeline
  # @return [ProcessingResult] The result of the processing
  def execute
    @logger.info("Starting processing pipeline for #{@task.process_type} on #{@task.processable.class.name}")

    @task.mark_started
    update_status(:processing)

    begin
      # Step 1: Collect data
      data = collect_data

      # Step 2: Build prompt using existing PromptBuilder
      prompt = build_prompt(data)

      # Step 3: Send to LLM
      response = send_to_llm(prompt)

      # Step 4: Parse response
      parsed_result = parse_response(response)

      # Step 5: Store result
      store_result(parsed_result)

      # Finalize
      @task.mark_completed
      @task.record_metric(:status, "completed")
      @task.record_metric(:processing_time_ms, @task.processing_time_ms)

      # Record metrics to database
      save_processing_metrics(parsed_result)

      update_status(:completed)
      broadcast_update(:completed, parsed_result)

      ProcessingResult.new(success: true, data: parsed_result)
    rescue => e
      handle_error(e)
    end
  end

  private

  # Step 1: Collect data for processing
  def collect_data
    DataCollectionService.for(@task.processable, @task.process_type)
  end

  # Step 2: Build prompt using existing PromptBuilder
  def build_prompt(data)
    prompt = PromptBuilder.build(@task.prompt_template, data)
    @task.record_metric(:prompt_length, prompt.length)
    prompt
  end

  # Step 3: Send the prompt to the LLM
  def send_to_llm(prompt)
    llm_request = LLMRequest.new(
      prompt: prompt,
      llm_model_name: @task.model_name,
      request_type: @task.process_type,
      trackable: @task.processable,
      user: @task.user,
      metadata: @task.context,
      temperature: @task.configuration.temperature || 0.2,
      max_tokens: @task.configuration.max_tokens || 4000
    )

    response = LLM::Client.new.generate(llm_request)
    @task.record_metric(:tokens, response[:metadata][:tokens])
    response
  end

  # Step 4: Parse the LLM response
  def parse_response(response)
    parser_class = @task.response_parser
    parser = ResponseParserFactory.create(parser_class)
    parsed = parser.parse(response[:content])
    @task.record_metric(:parsed_result_type, parsed.class.name)
    parsed
  end

  # Step 5: Store the processed result
  def store_result(result)
    storage_class = @task.storage_service
    storage = StorageServiceFactory.create(storage_class)
    storage.store(@task.processable, result)
  end

  # Update the status of the processable
  def update_status(status)
    return unless @task.status_manager

    status_manager = StatusManagerFactory.create(@task.status_manager)
    status_manager.update_status(@task.processable, status)
  end

  # Broadcast an update about the processing
  def broadcast_update(event, data = nil)
    return unless @task.broadcaster

    broadcaster = BroadcasterFactory.create(@task.broadcaster)
    broadcaster.broadcast(@task.processable, event, data)
  end

  # Handle errors during processing
  def handle_error(error)
    @logger.error("Error in processing pipeline: #{error.message}")
    @logger.error(error.backtrace.join("\n"))

    @task.error_message = error.message
    @task.record_metric(:status, "failed")
    @task.record_metric(:error, error.message)

    # Record error metrics to database
    save_processing_metrics(nil, error)

    update_status(:failed)
    broadcast_update(:failed, { error: error.message })

    ProcessingResult.new(success: false, error: error.message)
  end

  # Save processing metrics to the ProcessingMetric model
  def save_processing_metrics(result = nil, error = nil)
    # This is a placeholder until we implement the ProcessingMetric model
    # The implementation will create a ProcessingMetric record with all the collected metrics
    @logger.info("Metrics will be saved once ProcessingMetric model is implemented")

    # When ProcessingMetric is implemented, it will look something like:
    # metric = ProcessingMetric.new(
    #   processable: @task.processable,
    #   process_type: @task.process_type,
    #   user: @task.user,
    #   started_at: @task.started_at,
    #   completed_at: @task.completed_at,
    #   duration_ms: @task.processing_time_ms,
    #   status: @task.metrics[:status],
    #   error_message: error&.message,
    #   # ... other attributes
    # )
    # metric.save!
    # metric
  end
end
