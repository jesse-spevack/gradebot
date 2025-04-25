require "application_system_test_case"

class VisitRootTest < ApplicationSystemTestCase
  test "visiting the root route" do
    visit root_path
    assert_selector "h2", text: "Why Teachers Choose GradeBot"
  end
end
