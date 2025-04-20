require "test_helper"

class StrengthTest < ActiveSupport::TestCase
  test "valid strength with all attributes" do
    # Setup
    strength = Strength.new(
      recordable: student_submissions(:pending_submission),
      content: "Clear and structured writing",
      reason: "The submission follows a logical structure with well-organized paragraphs."
    )

    # Exercise & Verify
    assert strength.valid?
  end

  test "invalid without recordable" do
    # Setup
    strength = Strength.new(
      content: "Clear and structured writing",
      reason: "The submission follows a logical structure with well-organized paragraphs."
    )

    # Exercise & Verify
    assert_not strength.valid?
    assert_includes strength.errors[:recordable], "must exist"
  end

  test "invalid without content" do
    # Setup
    strength = Strength.new(
      recordable: student_submissions(:pending_submission),
      reason: "The submission follows a logical structure with well-organized paragraphs."
    )

    # Exercise & Verify
    assert_not strength.valid?
    assert_includes strength.errors[:content], "can't be blank"
  end

  test "invalid without reason" do
    # Setup
    strength = Strength.new(
      recordable: student_submissions(:pending_submission),
      content: "Clear and structured writing"
    )

    # Exercise & Verify
    assert_not strength.valid?
    assert_includes strength.errors[:reason], "can't be blank"
  end

  test "can belong to student_submission" do
    # Setup
    strength = strengths(:writing_structure)

    # Exercise & Verify
    assert_equal "StudentSubmission", strength.recordable_type
    assert strength.recordable.is_a?(StudentSubmission)
  end

  test "can belong to grading_task_summary" do
    # Setup
    strength = Strength.new(
      recordable_type: "GradingTaskSummary",
      recordable_id: 1,
      content: "Overall strong writing skills",
      reason: "Students demonstrate good grammar and structure."
    )

    # Exercise & Verify
    assert_equal "GradingTaskSummary", strength.recordable_type
  end
end
