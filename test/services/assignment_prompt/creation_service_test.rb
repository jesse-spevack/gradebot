require "test_helper"

class AssignmentPrompt::CreationServiceTest < ActiveSupport::TestCase
  include ActionText::SystemTestHelper

  test "creates an assignment prompt with valid parameters" do
    # Setup
    user = users(:teacher)
    grading_task = GradingTask.create!(user: user, status: :created)

    # Exercise
    assignment_prompt = AssignmentPrompt::CreationService.call(
      grading_task: grading_task,
      title: "Test Assignment",
      subject: "English",
      grade_level: "10",
      word_count: 500,
      content: "<div>Write an essay about climate change.</div>"
    )

    # Verify
    assert assignment_prompt.persisted?
    assert_equal grading_task, assignment_prompt.grading_task
    assert_equal "Test Assignment", assignment_prompt.title
    assert_equal "English", assignment_prompt.subject
    assert_equal "10", assignment_prompt.grade_level
    assert_equal 500, assignment_prompt.word_count
    assert_not_nil assignment_prompt.content
  end

  test "saves due_date when provided" do
    # Setup
    user = users(:teacher)
    grading_task = GradingTask.create!(user: user, status: :created)
    due_date = Date.new(2025, 5, 15)

    # Exercise
    assignment_prompt = AssignmentPrompt::CreationService.call(
      grading_task: grading_task,
      grade_level: "10",
      subject: "World History",
      title: "Assignment with Due Date",
      content: "Submit your essay by the due date",
      due_date: due_date
    )

    # Verify
    assert assignment_prompt.persisted?
    assert_equal due_date, assignment_prompt.due_date
    assert_equal "Assignment with Due Date", assignment_prompt.title
  end

  test "raises error when missing required parameters" do
    # Setup
    user = users(:teacher)
    grading_task = GradingTask.create!(user: user, status: :created)

    # Exercise & Verify
    assert_raises(ArgumentError) do
      # Missing title parameter
      AssignmentPrompt::CreationService.call(
        grading_task: grading_task,
        content: "Some content",
        subject: "English",
        grade_level: "10"
      )
    end
  end
end
