# frozen_string_literal: true

require "test_helper"

class StorageServiceFactoryTest < ActiveSupport::TestCase
  test "should create a storage service instance from a class" do
    # Setup - create a mock storage service for testing
    storage_class = Class.new do
      def store(processable, result); end
    end

    # Exercise
    storage = StorageServiceFactory.create(storage_class)

    # Verify
    assert_instance_of storage_class, storage
  end

  test "should create a storage service instance from a class name string" do
    # Since we can't easily define constants in tests, we'll stub the constantize method
    mock_class = Class.new do
      def store(processable, result); end
    end

    mock_string = Minitest::Mock.new
    mock_string.expect(:is_a?, true, [ String ])
    mock_string.expect(:constantize, mock_class)

    # Exercise
    storage = StorageServiceFactory.create(mock_string)

    # Verify
    assert_instance_of mock_class, storage
    assert_mock mock_string
  end

  test "should raise ArgumentError for unknown storage service class" do
    # Setup
    unknown_class = "NonExistentStorageService"

    # Exercise & Verify
    assert_raises ArgumentError do
      StorageServiceFactory.create(unknown_class)
    end
  end
end
