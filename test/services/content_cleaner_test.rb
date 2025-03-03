# frozen_string_literal: true

require "test_helper"

class ContentCleanerTest < ActiveSupport::TestCase
  test "returns empty string for nil content" do
    assert_equal "", ContentCleaner.clean(nil)
  end

  test "truncates long content" do
    long_content = "a" * (ContentCleaner::MAX_LENGTH + 100)
    cleaned = ContentCleaner.clean(long_content)

    assert_equal ContentCleaner::MAX_LENGTH, cleaned.length
  end

  test "replaces tabs with spaces" do
    content = "test\tcontent"
    assert_equal "test    content", ContentCleaner.clean(content)
  end

  test "normalizes line endings" do
    content = "test\r\ncontent\r"
    assert_equal "test\ncontent\n", ContentCleaner.clean(content)
  end

  test "removes control characters" do
    content = "test\x00content\x1F"
    assert_equal "testcontent", ContentCleaner.clean(content)
  end
end
