# frozen_string_literal: true

class StudentSubmission::Processor
  class << self
    def process(student_submission:)
      new(student_submission: student_submission).execute
    end
  end

  def initialize(student_submission:)
    @student_submission = student_submission
  end

  def execute
    return nil unless @student_submission

    begin
      @student_submission = StudentSubmission::AttemptTracker.track(@student_submission)
      @student_submission = StudentSubmission::StatusUpdater.transition_student_submission_to_processing(@student_submission)
      document_content = StudentSubmission::DocumentContentFetcherService.fetch(
        student_submission: @student_submission
      )
      grading_response = Grading::GradingOrchestrator.grade(
        student_submission: @student_submission,
        document_content: document_content
      )
      StudentSubmission::RecordResultService.record(
        student_submission: @student_submission,
        grading_response: grading_response,
        document_content: document_content
      )
    rescue => e
      puts e.message
      puts e.backtrace
      StudentSubmission::StatusUpdater.transition_student_submission_to_failed(
        @student_submission,
        { feedback: "Failed to complete grading: #{e.message}" }
      )
      raise e
    end
  end
end
