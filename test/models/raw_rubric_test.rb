require "test_helper"

class RawRubricTest < ActiveSupport::TestCase
  test "valid raw_rubric with all attributes" do
    # Setup
    raw_rubric = RawRubric.new(
      content: "This is a raw rubric content",
      grading_task: grading_tasks(:two),
      rubric: rubrics(:essay_rubric)
    )

    # Exercise & Verify
    assert raw_rubric.valid?
  end

  test "invalid without content" do
    # Setup
    raw_rubric = RawRubric.new(
      grading_task: grading_tasks(:two),
      rubric: rubrics(:essay_rubric)
    )

    # Exercise & Verify
    assert_not raw_rubric.valid?
    assert_includes raw_rubric.errors[:content], "can't be blank"
  end

  test "invalid without grading_task" do
    # Setup
    raw_rubric = RawRubric.new(
      content: "This is a raw rubric content",
      rubric: rubrics(:essay_rubric)
    )

    # Exercise & Verify
    assert_not raw_rubric.valid?
    assert_includes raw_rubric.errors[:grading_task], "must exist"
  end

  test "valid without rubric" do
    # Setup
    raw_rubric = RawRubric.new(
      content: "This is a raw rubric content",
      grading_task: grading_tasks(:two)
    )

    # Exercise & Verify
    assert raw_rubric.valid?
  end

  test "belongs to grading_task" do
    # Setup
    raw_rubric = raw_rubrics(:math_raw_rubric)

    # Exercise & Verify
    assert_respond_to raw_rubric, :grading_task
  end

  test "belongs to rubric (optional)" do
    # Setup
    raw_rubric = raw_rubrics(:math_raw_rubric)

    # Exercise & Verify
    assert_respond_to raw_rubric, :rubric
  end
end
