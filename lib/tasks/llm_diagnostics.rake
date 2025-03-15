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
  end
end
