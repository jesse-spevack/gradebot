module LLM
  # A simple event system for LLM-related events
  module EventSystem
    # Event types
    EVENTS = {
      request_completed: "llm.request.completed"
    }.freeze

    # The Publisher handles dispatching events to registered subscribers
    class Publisher
      class << self
        def subscribers
          @subscribers ||= Hash.new { |h, k| h[k] = [] }
        end

        # Register a subscriber for an event
        def subscribe(event_type, subscriber)
          subscribers[event_type] << subscriber
          Rails.logger.debug "LLM::EventSystem - Subscriber #{subscriber.class.name} registered for #{event_type}"
        end

        # Publish an event to all subscribers
        def publish(event_type, payload = {})
          Rails.logger.debug "LLM::EventSystem - Publishing event: #{event_type}"
          subscribers[event_type].each do |subscriber|
            begin
              subscriber.handle_event(event_type, payload)
            rescue => e
              Rails.logger.error "LLM::EventSystem - Error in subscriber #{subscriber.class.name}: #{e.message}"
              Rails.logger.error e.backtrace.join("\n")
            end
          end
        end

        # Remove all subscribers (useful for testing)
        def clear!
          @subscribers = Hash.new { |h, k| h[k] = [] }
        end
      end
    end

    # Base class for all event subscribers
    module Subscriber
      def handle_event(event_type, payload)
        method_name = "on_#{event_type.to_s.gsub('.', '_')}"
        send(method_name, payload) if respond_to?(method_name)
      end

      # Subscribe to an event
      def subscribe_to(event_type)
        Publisher.subscribe(event_type, self)
      end
    end
  end
end
