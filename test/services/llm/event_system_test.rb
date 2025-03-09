require "test_helper"

class LLM::EventSystemTest < ActiveSupport::TestCase
  setup do
    # Clear any existing subscribers before each test
    LLM::EventSystem::Publisher.clear!
  end

  test "publisher can register subscribers" do
    subscriber = MockSubscriber.new
    LLM::EventSystem::Publisher.subscribe("test.event", subscriber)

    assert_equal 1, LLM::EventSystem::Publisher.subscribers["test.event"].size
    assert_equal subscriber, LLM::EventSystem::Publisher.subscribers["test.event"].first
  end

  test "publisher can publish events to subscribers" do
    subscriber = MockSubscriber.new
    LLM::EventSystem::Publisher.subscribe("test.event", subscriber)

    payload = { data: "test" }
    LLM::EventSystem::Publisher.publish("test.event", payload)

    assert_equal 1, subscriber.events.size
    assert_equal "test.event", subscriber.events.first[:event_type]
    assert_equal payload, subscriber.events.first[:payload]
  end

  test "subscriber module provides handle_event method" do
    subscriber = MockSubscriber.new

    # Test with a method that exists
    subscriber.handle_event("test_event", { data: "test" })
    assert_equal 1, subscriber.events.size

    # Test with a method that doesn't exist
    assert_nothing_raised do
      subscriber.handle_event("nonexistent_event", { data: "test" })
    end
  end

  test "subscriber can subscribe to events" do
    subscriber = MockSubscriber.new
    subscriber.subscribe_to("test.event")

    assert_equal 1, LLM::EventSystem::Publisher.subscribers["test.event"].size
    assert_equal subscriber, LLM::EventSystem::Publisher.subscribers["test.event"].first
  end

  # Mock subscriber for testing
  class MockSubscriber
    include LLM::EventSystem::Subscriber

    attr_reader :events

    def initialize
      @events = []
    end

    def on_test_event(payload)
      @events << { event_type: "test.event", payload: payload }
    end
  end
end
