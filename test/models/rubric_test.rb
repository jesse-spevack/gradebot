require "test_helper"

class RubricTest < ActiveSupport::TestCase
  test "valid rubric with all attributes" do
    # Setup
    rubric = Rubric.new(
      title: "Essay Rubric",
      user: users(:teacher),
      total_points: 100,
      status: :pending
    )

    # Exercise & Verify
    assert rubric.valid?
  end

  test "invalid without title" do
    # Setup
    rubric = Rubric.new(
      user: users(:teacher),
      total_points: 100,
      status: :pending
    )

    # Exercise & Verify
    assert_not rubric.valid?
    assert_includes rubric.errors[:title], "can't be blank"
  end

  test "invalid without user" do
    # Setup
    rubric = Rubric.new(
      title: "Essay Rubric",
      total_points: 100,
      status: :pending
    )

    # Exercise & Verify
    assert_not rubric.valid?
    assert_includes rubric.errors[:user], "must exist"
  end

  test "default status is pending" do
    # Setup
    rubric = Rubric.new(
      title: "Essay Rubric",
      user: users(:teacher),
      total_points: 100
    )

    # Exercise & Verify
    assert_equal "pending", rubric.status
  end

  test "default total_points is 100" do
    # Setup
    rubric = Rubric.new(
      title: "Essay Rubric",
      user: users(:teacher)
    )

    # Exercise & Verify
    assert_equal 100, rubric.total_points
  end

  test "has many criteria" do
    # Setup
    rubric = rubrics(:essay_rubric)

    # Exercise & Verify
    assert_respond_to rubric, :criteria
  end

  test "has one raw_rubric" do
    # Setup
    rubric = rubrics(:essay_rubric)

    # Exercise & Verify
    assert_respond_to rubric, :raw_rubric
  end

  test "has many grading_tasks" do
    # Setup
    rubric = rubrics(:essay_rubric)
    grading_task = GradingTask.create!(
      user: users(:teacher),
      status: "pending",
      rubric: rubric
    )

    # Exercise & Verify
    assert_respond_to rubric, :grading_tasks
    assert_includes rubric.grading_tasks, grading_task
  end

  test "display_status returns correct display-friendly status" do
    # Setup
    rubric = Rubric.new(user: users(:teacher), title: "Test Rubric")

    # Test pending/processing status
    rubric.status = :pending
    assert_equal "processing", rubric.display_status

    rubric.status = :processing
    assert_equal "processing", rubric.display_status

    # Test complete status
    rubric.status = :complete
    assert_equal "completed", rubric.display_status

    # Test failed status
    rubric.status = :failed
    assert_equal "failed", rubric.display_status
  end
end
