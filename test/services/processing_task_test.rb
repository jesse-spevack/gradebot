# frozen_string_literal: true

require "test_helper"

class ProcessingTaskTest < ActiveSupport::TestCase
  setup do
    # Use mocks instead of fixtures
    @user = Minitest::Mock.new
    @processable = Minitest::Mock.new
    @process_type = "grade_student_work"
    @model_name = "gpt-4"
    @configuration = { temperature: 0.2, max_tokens: 2000 }
    @prompt_template = "student_work_grading"
    @response_parser = "Parsers::StudentWorkParser"
    @storage_service = "StudentWorkStorageService"
    @status_manager = "StudentWorkStatusManager"
    @broadcaster = "StudentWorkBroadcaster"
    @context = { assignment_id: 123, class_id: 456 }

    # Configuration should contain all the task configuration parameters
    config = {
      model: @model_name,
      prompt_template: @prompt_template,
      response_parser: @response_parser,
      storage_service: @storage_service,
      status_manager: @status_manager,
      broadcaster: @broadcaster,
      temperature: 0.2,
      max_tokens: 2000
    }

    @task = ProcessingTask.new(
      processable: @processable,
      process_type: @process_type,
      user: @user,
      configuration: config,
      context: @context
    )
  end

  test "should initialize with attributes" do
    # Create a real instance for this test rather than using mocks
    processable = Object.new
    process_type = "grade_student_work"
    user = Object.new
    model_name = "gpt-4"
    prompt_template = "student_work_grading"
    response_parser = "Parsers::StudentWorkParser"
    storage_service = "StudentWorkStorageService"
    status_manager = "StudentWorkStatusManager"
    broadcaster = "StudentWorkBroadcaster"
    context = { assignment_id: 123 }
    configuration = {
      model: model_name,
      prompt_template: prompt_template,
      response_parser: response_parser,
      storage_service: storage_service,
      status_manager: status_manager,
      broadcaster: broadcaster
    }

    task = ProcessingTask.new(
      processable: processable,
      process_type: process_type,
      user: user,
      configuration: configuration,
      context: context
    )

    # Verify
    assert_same processable, task.processable
    assert_equal process_type, task.process_type
    assert_same user, task.user
    assert_equal model_name, task.model_name
    assert_equal prompt_template, task.prompt_template
    assert_equal response_parser, task.response_parser
    assert_equal storage_service, task.storage_service
    assert_equal status_manager, task.status_manager
    assert_equal broadcaster, task.broadcaster
    # Context is wrapped with indifferent access, so check the content not the object
    assert_equal context[:assignment_id], task.context[:assignment_id]
    assert_equal({}, task.metrics)
    assert_nil task.started_at
    assert_nil task.completed_at
    assert_nil task.error_message
  end

  test "should validate presence of required attributes" do
    # Verify that an exception is raised for each missing required attribute
    assert_raises(ArgumentError, "Processable is required") do
      ProcessingTask.new(process_type: @process_type, configuration: config = { model: "gpt-4" })
    end

    assert_raises(ArgumentError, "Process type is required") do
      ProcessingTask.new(processable: @processable, configuration: config = { model: "gpt-4" })
    end

    assert_raises(ArgumentError, "Configuration is required") do
      ProcessingTask.new(processable: @processable, process_type: @process_type, configuration: nil)
    end

    assert_raises(ArgumentError, "Prompt template is required") do
      ProcessingTask.new(
        processable: @processable,
        process_type: @process_type,
        configuration: { model: "gpt-4" }
      )
    end
  end

  test "should mark as started" do
    # Exercise
    @task.mark_started

    # Verify
    assert_not_nil @task.started_at
    assert_nil @task.completed_at
  end

  test "should mark as completed" do
    # Setup
    @task.mark_started

    # Exercise
    @task.mark_completed

    # Verify
    assert_not_nil @task.started_at
    assert_not_nil @task.completed_at
  end

  test "should calculate processing time" do
    # Setup
    @task.mark_started
    travel 1.second
    @task.mark_completed

    # Exercise & Verify
    assert_operator @task.processing_time_ms, :>, 0
    assert_operator @task.processing_time_ms, :<=, 1100 # Allow a little buffer for test execution
  end

  test "should record metrics" do
    # Exercise
    @task.record_metric(:tokens, 150)
    @task.record_metric(:cost, 0.002)

    # Verify
    assert_equal 150, @task.metrics[:tokens]
    assert_equal 0.002, @task.metrics[:cost]
  end

  test "should determine if started" do
    # Setup
    assert_not @task.started?

    # Exercise
    @task.mark_started

    # Verify
    assert @task.started?
  end

  test "should determine if completed" do
    # Setup
    assert_not @task.completed?

    # Exercise
    @task.mark_started
    @task.mark_completed

    # Verify
    assert @task.completed?
  end

  test "should include metrics in metadata" do
    # Setup - Create a basic task
    task = ProcessingTask.new(
      processable: Object.new,
      process_type: "grade_student_work",
      configuration: {
        model: "gpt-4",
        prompt_template: "student_work_grading",
        response_parser: "Parsers::StudentWorkParser",
        storage_service: "StudentWorkStorageService"
      }
    )

    # Add a single metric
    task.record_metric(:test_metric, "test_value")

    # Exercise - Call metadata
    metadata = task.metadata

    # Verify - Check the metric was included
    assert_equal "test_value", metadata[:test_metric], "Metrics should be merged into metadata"

    # Verify other core metadata values
    assert_equal "grade_student_work", metadata[:process_type]
    assert_equal "gpt-4", metadata[:model_name]
  end

  test "should add time-based information to metadata" do
    freeze_time
    # Setup - Create a task with timing information
    task = ProcessingTask.new(
      processable: Object.new,
      process_type: "grade_student_work",
      configuration: {
        model: "gpt-4",
        prompt_template: "student_work_grading",
        response_parser: "Parsers::StudentWorkParser",
        storage_service: "StudentWorkStorageService"
      }
    )

    # Set timing information
    task.mark_started

    travel 1.second
    task.mark_completed

    # Exercise
    metadata = task.metadata

    # Verify
    assert_not_nil metadata[:started_at]
    assert_not_nil metadata[:completed_at]
    assert metadata[:processing_time_ms] > 0
  end
end
