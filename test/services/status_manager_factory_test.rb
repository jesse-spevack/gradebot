# frozen_string_literal: true

require "test_helper"

class StatusManagerFactoryTest < ActiveSupport::TestCase
  test "should create a status manager instance from a class" do
    # Setup - create a mock status manager for testing
    status_manager_class = Class.new do
      def update_status(processable, status); end
    end

    # Exercise
    status_manager = StatusManagerFactory.create(status_manager_class)

    # Verify
    assert_instance_of status_manager_class, status_manager
  end

  test "should create a status manager instance from a class name string" do
    # Since we can't easily define constants in tests, we'll stub the constantize method
    mock_class = Class.new do
      def update_status(processable, status); end
    end

    mock_string = Minitest::Mock.new
    mock_string.expect(:is_a?, true, [ String ])
    mock_string.expect(:constantize, mock_class)

    # Exercise
    status_manager = StatusManagerFactory.create(mock_string)

    # Verify
    assert_instance_of mock_class, status_manager
    assert_mock mock_string
  end

  test "should return nil for nil status manager class" do
    # Exercise
    status_manager = StatusManagerFactory.create(nil)

    # Verify
    assert_nil status_manager
  end

  test "should raise ArgumentError for unknown status manager class" do
    # Setup
    unknown_class = "NonExistentStatusManager"

    # Exercise & Verify
    assert_raises ArgumentError do
      StatusManagerFactory.create(unknown_class)
    end
  end
end
