# frozen_string_literal: true

require "test_helper"

class BroadcasterFactoryTest < ActiveSupport::TestCase
  test "should create a broadcaster instance from a class" do
    # Setup - create a mock broadcaster for testing
    broadcaster_class = Class.new do
      def broadcast(processable, event, data); end
    end

    # Exercise
    broadcaster = BroadcasterFactory.create(broadcaster_class)

    # Verify
    assert_instance_of broadcaster_class, broadcaster
  end

  test "should create a broadcaster instance from a class name string" do
    # Since we can't easily define constants in tests, we'll stub the constantize method
    mock_class = Class.new do
      def broadcast(processable, event, data); end
    end

    mock_string = Minitest::Mock.new
    mock_string.expect(:is_a?, true, [ String ])
    mock_string.expect(:constantize, mock_class)

    # Exercise
    broadcaster = BroadcasterFactory.create(mock_string)

    # Verify
    assert_instance_of mock_class, broadcaster
    assert_mock mock_string
  end

  test "should return nil for nil broadcaster class" do
    # Exercise
    broadcaster = BroadcasterFactory.create(nil)

    # Verify
    assert_nil broadcaster
  end

  test "should raise ArgumentError for unknown broadcaster class" do
    # Setup
    unknown_class = "NonExistentBroadcaster"

    # Exercise & Verify
    assert_raises ArgumentError do
      BroadcasterFactory.create(unknown_class)
    end
  end
end
