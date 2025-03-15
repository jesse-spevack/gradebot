namespace :llm do
  namespace :diagnostics do
    desc "Test LLM cost tracking subscriber initialization"
    task test_subscriber: :environment do
      puts "Starting LLM cost tracking subscriber test..."

      begin
        # Check if required classes are loaded
        puts "Checking if required modules are loaded..."

        event_system_loaded = defined?(LLM::EventSystem)
        cost_tracking_loaded = defined?(LLM::CostTracking)
        subscriber_loaded = defined?(LLM::CostTrackingSubscriber)

        puts "LLM::EventSystem loaded: #{event_system_loaded ? 'YES' : 'NO'}"
        puts "LLM::CostTracking loaded: #{cost_tracking_loaded ? 'YES' : 'NO'}"
        puts "LLM::CostTrackingSubscriber loaded: #{subscriber_loaded ? 'YES' : 'NO'}"

        if event_system_loaded && cost_tracking_loaded && subscriber_loaded
          puts "All required modules are loaded, initializing subscriber..."

          # Try to initialize the subscriber
          subscriber = LLM::CostTrackingSubscriber.new
          puts "Subscriber initialized successfully: #{subscriber.class.name}"

          # Check if we can access the event system
          if defined?(LLM::EventSystem::EVENTS) && LLM::EventSystem::EVENTS[:request_completed]
            puts "Event system appears to be working correctly"
            puts "Request completed event name: #{LLM::EventSystem::EVENTS[:request_completed]}"
          else
            puts "WARNING: Could not access event system events"
          end

          # Test creating a cost log directly
          puts "Testing direct cost log creation..."
          begin
            log = LLMCostLog.create!(
              llm_model_name: "test-model",
              cost: 0.01
            )
            puts "Successfully created test cost log with ID: #{log.id}"
          rescue => e
            puts "ERROR: Failed to create test cost log: #{e.message}"
            puts e.backtrace.first(5)
          end
        else
          puts "ERROR: Some required modules are not loaded"
        end
      rescue => e
        puts "ERROR: Test failed with exception: #{e.message}"
        puts e.backtrace.first(10)
      end

      puts "LLM cost tracking subscriber test completed"
    end

    desc "Test full LLM request flow with cost tracking"
    task test_request_flow: :environment do
      puts "=== Testing Full LLM Request Flow with Cost Tracking ==="

      # Clear existing test logs to make it easier to identify new ones
      test_logs = LLMCostLog.where(llm_model_name: "test-model-flow")
      if test_logs.any?
        puts "Clearing #{test_logs.count} existing test logs..."
        test_logs.destroy_all
      end

      puts "\nSetting up test..."

      # Create a request with a unique identifier
      test_id = "flow-test-#{Time.now.to_i}"
      request_id = SecureRandom.uuid

      puts "Created test ID: #{test_id}"
      puts "Created request ID: #{request_id}"

      # Create the request object with all tracking information
      # The LLMRequest object's to_context method will automatically build the context hash
      # used for cost tracking
      request = LLMRequest.new(
        prompt: "This is a test prompt to verify cost tracking flow. Please respond with a short message.",
        llm_model_name: "claude-3-haiku", # Use the smallest/cheapest model for testing
        request_type: "diagnostic_test",
        request_id: request_id,
        metadata: {
          test_id: test_id,
          source: "test_request_flow"
        }
      )

      puts "Created LLM request with model: #{request.llm_model_name}"
      puts "Request context: #{request.to_context.inspect}"

      begin
        puts "\nExecuting LLM request..."
        client = LLM::Client.new
        response = client.generate(request)

        puts "Response received:"
        puts "- Content: #{response[:content].to_s.truncate(100)}"

        if response[:metadata]
          puts "- Metadata present: yes"
          if response[:metadata][:tokens]
            tokens = response[:metadata][:tokens]
            puts "- Tokens: prompt=#{tokens[:prompt]}, completion=#{tokens[:completion]}, total=#{tokens[:total]}"
          else
            puts "- Tokens: not present in metadata"
          end
        else
          puts "- Metadata present: no"
        end

        # Wait a moment for async operations to complete
        puts "\nWaiting for cost tracking to complete..."
        sleep(2)

        # Check for cost logs
        puts "Checking for cost logs..."
        logs = LLMCostLog.where("created_at > ?", 5.minutes.ago).order(created_at: :desc).limit(5)

        if logs.any?
          puts "Found #{logs.count} recent cost logs:"
          logs.each do |log|
            puts "- ID: #{log.id}"
            puts "  Model: #{log.llm_model_name}"
            puts "  Request Type: #{log.request_type}"
            puts "  Request ID: #{log.request_id}"
            puts "  Tokens: #{log.total_tokens} (prompt: #{log.prompt_tokens}, completion: #{log.completion_tokens})"
            puts "  Cost: #{log.cost}"
            puts "  Created: #{log.created_at}"
            if log.metadata.present?
              puts "  Test ID in metadata: #{log.metadata['test_id']}"
            end
            puts ""
          end

          # Check specifically for our test log
          test_log = logs.find { |log| log.metadata.present? && log.metadata["test_id"] == test_id }
          if test_log
            puts "SUCCESS: Found matching cost log for this test with ID: #{test_log.id}"
          else
            puts "WARNING: No cost log found with our specific test ID: #{test_id}"
          end
        else
          puts "No recent cost logs found. Cost tracking may not be working correctly."
        end
      rescue => e
        puts "ERROR: Test failed with exception: #{e.message}"
        puts e.backtrace.first(10)
      end

      puts "=== Test Complete ==="
    end
  end
end
