require "test_helper"

class AssignmentPromptTest < ActiveSupport::TestCase
  # Setup some test data before running tests
  setup do
    # Make sure ActionText is available for tests
    @rich_text_content = ActionText::Content.new("<div>Test content</div>")
  end

  test "should validate presence of title" do
    # Setup
    prompt = AssignmentPrompt.new(
      subject: "Literary Analysis",
      grade_level: "10",
      word_count: 1000,
      grading_task: grading_tasks(:one)
    )
    prompt.content = @rich_text_content

    # Exercise and Verify
    assert_not prompt.valid?
    assert_includes prompt.errors[:title], "can't be blank"

    # Add title and verify it becomes valid
    prompt.title = "My Assignment"
    assert prompt.valid?
  end

  test "should validate presence of content" do
    # Setup
    prompt = AssignmentPrompt.new(
      title: "My Assignment",
      subject: "Literary Analysis",
      grade_level: "10",
      word_count: 1000,
      grading_task: grading_tasks(:one)
    )

    # Exercise and Verify
    assert_not prompt.valid?
    assert_includes prompt.errors[:content], "can't be blank"

    # Add content and verify it becomes valid
    prompt.content = @rich_text_content
    assert prompt.valid?
  end

  test "should belong to a grading task" do
    # Setup
    prompt = AssignmentPrompt.new(
      title: "My Assignment",
      subject: "Literary Analysis",
      grade_level: "10",
      word_count: 1000
    )
    prompt.content = @rich_text_content

    # Exercise and Verify
    assert_not prompt.valid?
    assert_includes prompt.errors[:grading_task], "must exist"

    # Add grading task and verify it becomes valid
    prompt.grading_task = grading_tasks(:one)
    assert prompt.valid?
  end

  test "should support rich text content" do
    # Setup
    prompt = AssignmentPrompt.new(
      title: "Rich Text Test",
      subject: "HTML Formatting",
      grade_level: "10",
      word_count: 1000,
      grading_task: grading_tasks(:one)
    )
    rich_content = "<div><strong>Bold text</strong> and <em>italic text</em></div>"

    # Exercise
    prompt.content = rich_content
    prompt.save
    prompt.reload

    # Verify - content should preserve HTML formatting
    assert_includes prompt.content.to_s, "<strong>Bold text</strong>"
    assert_includes prompt.content.to_s, "<em>italic text</em>"
  end

  test "grade_level_display should return the correct display name" do
    # Setup - test with different grade levels
    prompt_elementary = AssignmentPrompt.new(grade_level: "5")
    prompt_high_school = AssignmentPrompt.new(grade_level: "11")
    prompt_college = AssignmentPrompt.new(grade_level: "undergraduate")
    prompt_unknown = AssignmentPrompt.new(grade_level: "graduate") # Not in our constants

    # Exercise & Verify
    assert_equal "5th Grade", prompt_elementary.grade_level_display
    assert_equal "11th Grade", prompt_high_school.grade_level_display
    assert_equal "Undergraduate", prompt_college.grade_level_display
    assert_equal "graduate", prompt_unknown.grade_level_display # Falls back to original value
  end
end
