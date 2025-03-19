require "test_helper"

class SubmissionBroadcasterTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:one)
    @submission = student_submissions(:pending_submission)
  end

  test "broadcasts submission update correctly" do
    # Test that the broadcaster sends the correct broadcasts for a submission update
    assert_broadcasts("grading_task_#{@grading_task.id}", 6) do
      # The broadcast should update the submission card and table row
      broadcaster = SubmissionBroadcaster.new(@submission)
      broadcaster.broadcast_update
    end

    # Test that it also broadcasts to the submission detail page
    assert_broadcasts("student_submission_#{@submission.id}", 2) do
      # The broadcast should update the detail view and header status
      broadcaster = SubmissionBroadcaster.new(@submission)
      broadcaster.broadcast_update
    end
  end
end
