require "test_helper"
class StudentSubmission::AttemptTrackerTest < ActiveSupport::TestCase
  test "it tracks student submission attempts" do
    student_submission = StudentSubmission.create(
      grading_task: grading_tasks(:one),
      original_doc_id: "12345",
      status: :pending
    )

    assert_nil(student_submission.first_attempted_at)
    assert_equal(0, student_submission.attempt_count)

    student_submission = StudentSubmission::AttemptTracker.track(student_submission)

    refute_nil(student_submission.first_attempted_at)
    assert_equal(1, student_submission.attempt_count)
  end

  test "it tracks student submission attempts but does not change first_attempted_at timestamp" do
    now = Time.current
    student_submission = StudentSubmission.create(
      grading_task: grading_tasks(:one),
      original_doc_id: "12345",
      status: :pending,
      first_attempted_at: now
    )

    assert_equal(now, student_submission.first_attempted_at)
    assert_equal(0, student_submission.attempt_count)

    student_submission = StudentSubmission::AttemptTracker.track(student_submission)

    assert_equal(now, student_submission.first_attempted_at)
    assert_equal(1, student_submission.attempt_count)
  end
end
