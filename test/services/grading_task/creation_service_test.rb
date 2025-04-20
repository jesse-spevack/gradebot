require "test_helper"

class GradingTask::CreationServiceTest < ActiveSupport::TestCase
  test "creates a grading task with valid parameters" do
    # Setup
    user = users(:teacher)
    rubric = rubrics(:essay_rubric)
    feedback_tone = "encouraging"

    # Exercise
    grading_task = GradingTask::CreationService.call(
      user: user,
      rubric: rubric,
      feedback_tone: feedback_tone
    )

    # Verify
    assert grading_task.persisted?
    assert_equal user, grading_task.user
    assert_equal rubric, grading_task.rubric
    assert_equal "created", grading_task.status
    assert_equal feedback_tone, grading_task.feedback_tone
  end

  test "raises error when missing user" do
    # Exercise & Verify
    assert_raises(ActiveRecord::RecordInvalid) do
      GradingTask::CreationService.call(
        user: nil,
        rubric: rubrics(:essay_rubric)
      )
    end
  end
end
