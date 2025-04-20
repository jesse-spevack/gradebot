require "test_helper"

class GradingTaskTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)

    # Create a grading task - removed counter fields
    @grading_task = GradingTask.create!(
      user: @user,
      status: "created"
    )
  end

  test "should have association with rubric" do
    # Create a rubric
    rubric = Rubric.create!(
      title: "Test Rubric",
      user: @user,
      total_points: 100,
      status: :pending
    )

    # Associate rubric with grading task
    @grading_task.rubric = rubric
    @grading_task.save!
    @grading_task.reload

    # Verify the association
    assert_equal rubric, @grading_task.rubric
    assert_includes rubric.grading_tasks, @grading_task
  end

  test "should store feedback_tone" do
    # Setup
    grading_task = GradingTask.create!(
      user: @user,
      status: "created",
      feedback_tone: "encouraging"
    )

    # Verify the feedback_tone was stored
    assert_equal "encouraging", grading_task.feedback_tone

    # Update the feedback_tone
    grading_task.update!(feedback_tone: "critical")
    grading_task.reload

    # Verify the feedback_tone was updated
    assert_equal "critical", grading_task.feedback_tone
  end

  test "should validate feedback_tone" do
    # Setup
    grading_task = GradingTask.new(
      user: @user,
      status: "created",
      feedback_tone: "invalid_tone"
    )

    # Verify the validation fails
    assert_not grading_task.valid?
    assert_includes grading_task.errors[:feedback_tone], "is not included in the list"

    # Fix the feedback_tone
    grading_task.feedback_tone = "neutral"

    # Verify the validation passes
    assert grading_task.valid?
  end
end
