# frozen_string_literal: true

class DocumentAction::PostFeedbackService
  def self.post(document_action)
    new(document_action).post
  end

  attr_reader :document_action
  attr_reader :student_submission

  def initialize(document_action)
    @document_action = document_action
    @student_submission = document_action.student_submission
  end

  def post
    DocumentContentAppenderService.new(
      document_id: student_submission.original_doc_id,
      google_docs_client: google_docs_client
    ).append(student_submission.feedback)
  end

  private

  def google_docs_client
    GetGoogleDocsClientForStudentSubmissionCommand.call(student_submission: student_submission).result
  end
end
