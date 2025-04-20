require "test_helper"

class OpportunityTest < ActiveSupport::TestCase
  test "valid opportunity with all attributes" do
    # Setup
    opportunity = Opportunity.new(
      recordable: student_submissions(:pending_submission),
      content: "Paragraph structure and transitions",
      reason: "The submission would benefit from clearer paragraph transitions to improve flow."
    )

    # Exercise & Verify
    assert opportunity.valid?
  end

  test "invalid without recordable" do
    # Setup
    opportunity = Opportunity.new(
      content: "Paragraph structure and transitions",
      reason: "The submission would benefit from clearer paragraph transitions to improve flow."
    )

    # Exercise & Verify
    assert_not opportunity.valid?
    assert_includes opportunity.errors[:recordable], "must exist"
  end

  test "invalid without content" do
    # Setup
    opportunity = Opportunity.new(
      recordable: student_submissions(:pending_submission),
      reason: "The submission would benefit from clearer paragraph transitions to improve flow."
    )

    # Exercise & Verify
    assert_not opportunity.valid?
    assert_includes opportunity.errors[:content], "can't be blank"
  end

  test "invalid without reason" do
    # Setup
    opportunity = Opportunity.new(
      recordable: student_submissions(:pending_submission),
      content: "Paragraph structure and transitions"
    )

    # Exercise & Verify
    assert_not opportunity.valid?
    assert_includes opportunity.errors[:reason], "can't be blank"
  end

  test "can belong to student_submission" do
    # Setup
    opportunity = opportunities(:paragraph_structure)

    # Exercise & Verify
    assert_equal "StudentSubmission", opportunity.recordable_type
    assert opportunity.recordable.is_a?(StudentSubmission)
  end

  test "can belong to grading_task_summary" do
    # Setup
    opportunity = Opportunity.new(
      recordable_type: "GradingTaskSummary",
      recordable_id: 1,
      content: "Overall paragraph structure",
      reason: "Students across submissions need improvement in transitions between paragraphs."
    )

    # Exercise & Verify
    assert_equal "GradingTaskSummary", opportunity.recordable_type
  end
end
