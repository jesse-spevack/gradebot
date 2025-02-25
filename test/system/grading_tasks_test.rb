require "application_system_test_case"

class GradingTasksTest < ApplicationSystemTestCase
  include ActionView::RecordIdentifier
  test "critical path: creating a new grading task" do
    user = users(:teacher)
    login_as user
    visit new_grading_task_path

    # Verify form elements are present
    assert_selector "[data-testid='folder-picker']"
    assert_selector "textarea#grading_task_assignment_prompt"

    # Enter a valid prompt
    valid_prompt = "Write a 500-word essay about your favorite book and why it resonates with you."
    fill_in "grading_task[assignment_prompt]", with: valid_prompt
    assert_no_text "Assignment prompt must be"
  end

  test "assignment prompt validations" do
    user = users(:teacher)
    login_as user
    visit new_grading_task_path

    # Test validation - too short
    fill_in "grading_task[assignment_prompt]", with: "Too short"
    assert_text "Assignment prompt must be at least 10 characters"

    # Test validation - too long
    fill_in "grading_task[assignment_prompt]", with: "a" * 2001
    assert_text "Assignment prompt cannot exceed 2000 characters"
  end
end
