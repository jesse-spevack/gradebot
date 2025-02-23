require "application_system_test_case"

class TermsTest < ApplicationSystemTestCase
  test "visiting the terms of service page" do
    visit terms_path

    assert_selector "h1", text: "Terms of Service"
    assert_text "Welcome to GradeBot"
  end
end
