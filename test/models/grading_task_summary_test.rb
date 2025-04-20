require "test_helper"

class GradingTaskSummaryTest < ActiveSupport::TestCase
  test "valid grading_task_summary with all attributes" do
    # Setup
    summary = GradingTaskSummary.new(
      grading_task: grading_tasks(:one),
      submissions_count: 15,
      status: :completed,
      insights: "Most students performed well on content development but struggled with citations."
    )

    # Exercise & Verify
    assert summary.valid?
  end

  test "invalid without grading_task" do
    # Setup
    summary = GradingTaskSummary.new(
      submissions_count: 15,
      status: :completed,
      insights: "Most students performed well on content development but struggled with citations."
    )

    # Exercise & Verify
    assert_not summary.valid?
    assert_includes summary.errors[:grading_task], "must exist"
  end

  test "invalid without status" do
    # Setup
    summary = GradingTaskSummary.new(
      grading_task: grading_tasks(:one),
      submissions_count: 15,
      insights: "Most students performed well on content development but struggled with citations.",
      status: nil
    )

    # Exercise & Verify
    assert_not summary.valid?
    assert_includes summary.errors[:status], "can't be blank"
  end

  test "status enum works correctly" do
    # Setup
    summary = GradingTaskSummary.new(
      grading_task: grading_tasks(:one),
      status: :pending
    )

    # Exercise & Verify
    assert_equal "pending", summary.status

    # Change status
    summary.status = :processing
    assert_equal "processing", summary.status

    summary.status = :completed
    assert_equal "completed", summary.status
  end

  test "belongs to grading_task" do
    # Setup
    summary = grading_task_summaries(:essay_summary)

    # Exercise & Verify
    assert_respond_to summary, :grading_task
  end

  test "has many strengths" do
    # Setup
    summary = grading_task_summaries(:essay_summary)

    # Exercise & Verify
    assert_respond_to summary, :strengths
  end

  test "has many opportunities" do
    # Setup
    summary = grading_task_summaries(:essay_summary)

    # Exercise & Verify
    assert_respond_to summary, :opportunities
  end
end
