# frozen_string_literal: true

require "test_helper"

class ResponseParserFactoryTest < ActiveSupport::TestCase
  test "should create a parser instance from a class" do
    # Setup
    parser_class = Parsers::BaseResponseParser

    # Exercise
    parser = ResponseParserFactory.create(parser_class)

    # Verify
    assert_instance_of Parsers::BaseResponseParser, parser
  end

  test "should create a parser instance from a class name string" do
    # Since we can't easily define constants in tests, we'll stub the constantize method
    mock_class = Class.new do
      def parse(response); end
    end

    mock_string = Minitest::Mock.new
    mock_string.expect(:is_a?, true, [ String ])
    mock_string.expect(:constantize, mock_class)

    # Exercise
    parser = ResponseParserFactory.create(mock_string)

    # Verify
    assert_instance_of mock_class, parser
    assert_mock mock_string
  end

  test "should raise ArgumentError for unknown parser class" do
    # Setup
    unknown_class = "NonExistentParser"

    # Exercise & Verify
    assert_raises ArgumentError do
      ResponseParserFactory.create(unknown_class)
    end
  end
end
