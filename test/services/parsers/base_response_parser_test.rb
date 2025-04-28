# frozen_string_literal: true

require "test_helper"

class Parsers::BaseResponseParserTest < ActiveSupport::TestCase
  setup do
    @parser = Parsers::BaseResponseParser.new
  end

  test "should raise NotImplementedError when parse is called" do
    assert_raises NotImplementedError do
      @parser.parse("response")
    end
  end

  test "should parse valid JSON" do
    json_string = '{"key": "value"}'
    expected = { "key" => "value" }

    # Test the private method
    result = @parser.send(:parse_json, json_string)

    assert_equal expected, result
  end

  test "should raise ParseError for invalid JSON" do
    invalid_json = '{"key": "value"'

    assert_raises Parsers::ParseError do
      @parser.send(:parse_json, invalid_json)
    end
  end
end
