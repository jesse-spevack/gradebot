# frozen_string_literal: true

require "test_helper"

class StudentSubmissionJobTest < ActiveJob::TestCase
  # Setup
  setup do
    @student_submission = student_submissions(:pending_submission)
  end

  test "processes a student submission" do
    StudentSubmission::Processor.expects(:process).with(student_submission: @student_submission)

    StudentSubmissionJob.perform_now(@student_submission.id)
  end
end
