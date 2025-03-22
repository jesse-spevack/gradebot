# frozen_string_literal: true

class GetGoogleDriveClientForStudentSubmission < BaseCommand
  attr_reader :student_submission

  def initialize(student_submission:)
    super
  end

  def execute
    grading_task = student_submission.grading_task
    user = grading_task.user
    TokenService.new(user).create_google_drive_client
  rescue TokenService::TokenError => e
    Rails.logger.error("Failed to get access token for user #{user.id}: #{e.message}")
    raise StandardError, "Failed to get access token: #{e.message}"
  end
end
