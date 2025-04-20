require "test_helper"

class AssignmentSummaryTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:valid_assignment)
    @summary = assignment_summaries(:one) # Use fixture
  end

  test "invalid without assignment" do
    summary = AssignmentSummary.new(student_work_count: 5, qualitative_insights: "Good work overall")
    assert_not summary.valid?
    assert_not_empty summary.errors[:assignment]
  end

  test "invalid without student_work_count" do
    summary = AssignmentSummary.new(assignment: @assignment, qualitative_insights: "Good work overall")
    # Set to nil explicitly to test validation, bypassing default
    summary.student_work_count = nil
    assert_not summary.valid?
    assert_not_empty summary.errors[:student_work_count]
  end

  test "invalid student_work_count less than 0" do
    summary = AssignmentSummary.new(assignment: @assignment, student_work_count: -1, qualitative_insights: "Okay")
    assert_not summary.valid?
    assert_includes summary.errors[:student_work_count], "must be greater than or equal to 0"
  end

  test "invalid without qualitative_insights" do
    summary = AssignmentSummary.new(assignment: @assignment, student_work_count: 5)
    assert_not summary.valid?
    assert_not_empty summary.errors[:qualitative_insights]
  end

  test "valid assignment summary fixture" do
    assert @summary.valid?, "Fixture should be valid"
  end

  test "student_work_count defaults to 0" do
    # Test default value on a new record
    summary = AssignmentSummary.new(assignment: @assignment, qualitative_insights: "Insights")
    # Note: The default is applied by the DB, `new` doesn't trigger it directly.
    # We can assert it after saving or rely on the migration default.
    # For this test, let's check if it's 0 after potential initialization.
    assert_equal 0, summary.student_work_count, "Default student_work_count should be 0 on new record"
    # A more robust test might save and reload, but requires valid insights.
    # summary.save!
    # assert_equal 0, summary.reload.student_work_count
  end

  test "belongs to assignment" do
    # Use fixture
    assert_respond_to @summary, :assignment
    assert_equal @assignment, @summary.assignment
  end

  test "has many feedback_items (polymorphic)" do
    # Use fixture
    assert_respond_to @summary, :feedback_items
    # Can add items and test association
    # Example: Create a feedback item associated with this summary
    feedback = FeedbackItem.create!(feedbackable: @summary, kind: :strength, title: "Overall Strength", description: "Good progress")
    assert_includes @summary.reload.feedback_items, feedback
    # Check dependent destroy (if applicable)
    assert_difference("FeedbackItem.count", -1) do
      @summary.destroy
    end
  end

  test "has prefix id" do
    # Use fixture
    assert_respond_to @summary, :prefix_id
    assert @summary.prefix_id.starts_with?("asum_")
    # Unskip
    # skip "Prefix ID test requires model and table."
  end
end
