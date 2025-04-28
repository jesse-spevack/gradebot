# frozen_string_literal: true

require "test_helper"

class ProcessingPipelineTest < ActiveSupport::TestCase
  # Create a task stub class that can be used in tests
  class TaskStub
    attr_accessor :metrics, :error_message, :started_at, :completed_at

    def initialize
      @metrics = {}
      @error_message = nil
      @started_at = nil
      @completed_at = nil
    end

    def process_type; "grade_student_work"; end
    def processable; self; end
    def user; nil; end
    def model_name; "gpt-4"; end
    def prompt_template; "student_work_grading"; end
    def response_parser; "Parsers::StudentWorkParser"; end
    def storage_service; "StudentWorkStorageService"; end
    def status_manager; nil; end # Will be stubbed
    def broadcaster; nil; end # Will be stubbed
    def context; { assignment_id: 123 }; end
    def configuration; OpenStruct.new(temperature: 0.2, max_tokens: 2000); end
    def processing_time_ms; 1000; end

    def mark_started
      @started_at = Time.current
    end

    def mark_completed
      @completed_at = Time.current
    end

    def record_metric(key, value)
      @metrics[key] = value
    end
  end

  test "should execute pipeline successfully" do
    # Create a proper task stub
    task = TaskStub.new
    task.stub(:status_manager, "StudentWorkStatusManager") do
      task.stub(:broadcaster, "StudentWorkBroadcaster") do
        pipeline = ProcessingPipeline.new(task)

        # Stub the components called during pipeline execution
        data_collection_result = { title: "Assignment", student_work: "Content" }
        prompt = "This is the generated prompt"
        llm_response = { content: "response", metadata: { tokens: { input: 10, output: 20 } } }
        parsed_result = { overall_grade: 85, feedback: "Good work" }

        # Stub all external interactions
        DataCollectionService.stub :for, data_collection_result do
          PromptBuilder.stub :build, prompt do
            # Create a mock LLM client that returns a successful response
            mock_llm_client = Minitest::Mock.new
            mock_llm_client.expect(:generate, llm_response, [ LLMRequest ])

            # Create a mock response parser
            mock_parser = Minitest::Mock.new
            mock_parser.expect(:parse, parsed_result, [ String ])

            # Create a mock storage service
            mock_storage = Minitest::Mock.new
            mock_storage.expect(:store, nil, [ Object, Hash ])

            # Instead of mocking the status manager, create a stub that does nothing
            mock_status_manager = Object.new
            def mock_status_manager.update_status(processable, status); end

            # Instead of mocking the broadcaster, create a stub that does nothing
            mock_broadcaster = Object.new
            def mock_broadcaster.broadcast(processable, event, data); end

            # Stub the factory methods to return our stubs/mocks
            LLM::Client.stub :new, mock_llm_client do
              ResponseParserFactory.stub :create, mock_parser do
                StorageServiceFactory.stub :create, mock_storage do
                  StatusManagerFactory.stub :create, mock_status_manager do
                    BroadcasterFactory.stub :create, mock_broadcaster do
                      # Exercise
                      result = pipeline.execute

                      # Verify
                      assert_instance_of ProcessingResult, result
                      assert result.success?
                      assert_equal parsed_result, result.data

                      # Verify appropriate metrics were recorded
                      assert_equal "completed", task.metrics[:status]
                      assert_equal 1000, task.metrics[:processing_time_ms]
                      assert_equal 28, task.metrics[:prompt_length]

                      # Verify mocks where we need specific behavior validation
                      assert_mock mock_llm_client
                      assert_mock mock_parser
                      assert_mock mock_storage
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  test "should handle errors during execution" do
    # Setup - use the TaskStub for a cleaner approach
    task = TaskStub.new
    error_message = "Something went wrong"

    # Create a pipeline with our task stub
    task.stub(:status_manager, "StudentWorkStatusManager") do
      task.stub(:broadcaster, "StudentWorkBroadcaster") do
        pipeline = ProcessingPipeline.new(task)

        # Stub the components to raise an error
        DataCollectionService.stub :for, ->(_, _) { raise StandardError, error_message } do
          # Instead of mocking, use simple stubs that just implement the interface
          mock_status_manager = Object.new
          def mock_status_manager.update_status(processable, status); end

          mock_broadcaster = Object.new
          def mock_broadcaster.broadcast(processable, event, data); end

          # Stub the factory methods
          StatusManagerFactory.stub :create, mock_status_manager do
            BroadcasterFactory.stub :create, mock_broadcaster do
              # Exercise
              result = pipeline.execute

              # Verify
              assert_instance_of ProcessingResult, result
              assert_not result.success?
              assert_equal error_message, result.error

              # Verify that appropriate metrics were recorded
              assert_equal "failed", task.metrics[:status]
              assert_equal error_message, task.metrics[:error]
              assert_equal error_message, task.error_message
            end
          end
        end
      end
    end
  end
end
