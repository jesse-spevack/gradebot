# frozen_string_literal: true

class StudentSubmission::AttemptTracker
  class << self
    def track(student_submission)
      new(student_submission).execute
    end
  end

  attr_reader :student_submission

  def initialize(student_submission)
    @student_submission = student_submission
  end

  def execute
    if student_submission.first_attempted_at.nil?
      Rails.logger.info("First attempt for submission #{student_submission.id}")
      student_submission.update(first_attempted_at: Time.current, attempt_count: 1)
    else
      Rails.logger.info("Incrementing attempt count for student submission: #{student_submission.id}")
      student_submission.increment!(:attempt_count)
    end

    student_submission.reload
  end
end
