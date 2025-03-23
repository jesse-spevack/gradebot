# frozen_string_literal: true

require "test_helper"

class Grading::ContentCleanerTest < ActiveSupport::TestCase
  test "returns empty string for nil content" do
    assert_equal "", Grading::ContentCleaner.clean(nil)
  end

  test "truncates long content" do
    long_content = "a" * (Grading::ContentCleaner::MAX_LENGTH + 100)
    cleaned = Grading::ContentCleaner.clean(long_content)

    assert_equal Grading::ContentCleaner::MAX_LENGTH, cleaned.length
  end

  test "replaces tabs with spaces" do
    content = "test\tcontent"
    assert_equal "test    content", Grading::ContentCleaner.clean(content)
  end

  test "normalizes line endings" do
    content = "test\r\ncontent\r"
    assert_equal "test\ncontent\n", Grading::ContentCleaner.clean(content)
  end

  test "removes control characters" do
    content = "test\x00content\x1F"
    assert_equal "testcontent", Grading::ContentCleaner.clean(content)
  end
end
