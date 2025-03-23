# frozen_string_literal: true

class StudentSubmission::DocumentContentFetcherService
  class << self
    def fetch(student_submission:)
      new(student_submission: student_submission).fetch
    end
  end

  attr_reader :student_submission

  def initialize(student_submission:)
    @student_submission = student_submission
  end

  def fetch
    DocumentContentFetcherService.new(
      document_id: student_submission.original_doc_id,
      google_drive_client: google_drive_client
    ).fetch
  end

  def google_drive_client
    GetGoogleDriveClientForStudentSubmissionCommand.call(
      student_submission: student_submission
    ).result
  end
end
