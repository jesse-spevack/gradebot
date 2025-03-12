require "test_helper"

class LoadingIndicatorTest < ActionView::TestCase
  test "renders with default message" do
    content = "Test content"

    rendered = render partial: "shared/loading_indicator", locals: { content: content }

    assert_match content, rendered
    assert_match "Formatting with AI...", rendered
  end

  test "renders with custom message" do
    content = "Test content"
    message = "Custom loading message"

    rendered = render partial: "shared/loading_indicator", locals: { content: content, message: message }

    assert_match content, rendered
    assert_match message, rendered
    assert_no_match "Formatting with AI...", rendered
  end
end
