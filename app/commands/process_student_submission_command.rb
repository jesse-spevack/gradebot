# frozen_string_literal: true

# Command to process a student submission using LLM
#
# This command takes a student submission ID, retrieves the submission,
# and processes it to generate feedback. Currently, it just logs the submission ID.
class ProcessStudentSubmissionCommand < BaseCommand
  # Make student_submission_id explicitly available in the class
  attr_reader :student_submission_id

  def initialize(student_submission_id:)
    super
  end

  private

  # Execute the command logic
  # For now, this simply logs the student submission ID
  # In the future, this will use the LLM framework to generate feedback
  #
  # @return [StudentSubmission] The processed student submission
  def execute
    # Find the student submission by ID
    student_submission = StudentSubmission.find_by(id: student_submission_id)

    unless student_submission
      @errors << "Student submission not found with ID: #{student_submission_id}"
      return nil
    end

    # Update status to processing using the StatusManager
    unless StatusManager.transition_submission(student_submission, :processing)
      @errors << "Could not transition submission to processing state"
      return nil
    end

    # Log that we're starting processing
    Rails.logger.info("Processing student submission #{student_submission_id} for document: #{student_submission.original_doc_id}")

    # Get the grading task and user
    grading_task = student_submission.grading_task
    user = grading_task.user

    begin
      # Get a valid access token using TokenService
      token_service = TokenService.new(user)

      # Create a Google Drive client with user's token
      google_drive_client = token_service.create_google_drive_client

      # Fetch the document content using the client
      begin
        document_content = fetch_document_content(google_drive_client, student_submission.original_doc_id)
        Rails.logger.info("Successfully fetched document content for submission #{student_submission_id}")
      rescue => e
        Rails.logger.error("Error fetching document content: #{e.message}")
        @errors << "Failed to fetch document content: #{e.message}"
        StatusManager.transition_submission(
          student_submission,
          :failed,
          { feedback: "Failed to read document content: #{e.message}" }
        )
        return nil
      end

      # Grade the submission using our LLM grading service
      grade_with_llm(student_submission, document_content)

      # Return the student submission as the result
      student_submission
    rescue TokenService::TokenError => e
      Rails.logger.error("Token error for user #{user.id}: #{e.message}")
      @errors << "Failed to get access token: #{e.message}"

      # Transition to failed state due to token error
      StatusManager.transition_submission(
        student_submission,
        :failed,
        { feedback: "Failed to access Google Drive: #{e.message}" }
      )

      nil
    end
  end

  # Grade a submission using the LLM service
  #
  # @param student_submission [StudentSubmission] The submission to grade
  # @param document_content [String] The content of the document to grade
  # @return [Boolean] True if the grading succeeded, false otherwise
  def grade_with_llm(student_submission, document_content)
    # Get the grading task with assignment details
    grading_task = student_submission.grading_task

    # Create a new GradingService instance
    grading_service = GradingService.new

    # Grade the submission
    result = grading_service.grade_submission(
      document_content,
      grading_task.assignment_prompt,
      grading_task.grading_rubric
    )

    # Check if there was an error
    if result[:error].present?
      Rails.logger.error("Grading error: #{result[:error]}")
      @errors << "Failed to grade submission: #{result[:error]}"

      # Transition to failed state
      StatusManager.transition_submission(
        student_submission,
        :failed,
        { feedback: "Grading failed: #{result[:error]}" }
      )

      return false
    end

    # Log success
    Rails.logger.info("Successfully graded submission #{student_submission.id} with grade: #{result[:grade]}")

    # Transition to completed state with the feedback
    StatusManager.transition_submission(
      student_submission,
      :completed,
      {
        feedback: result[:feedback],
        graded_doc_id: "graded_#{student_submission.original_doc_id}"
        # We could store additional metadata like grade, rubric scores, etc.
        # in the database if we added those fields to the StudentSubmission model
      }
    )

    true
  end

  # Mock the grading process with random success/failure
  # In a real implementation, this would be replaced with actual document processing
  #
  # @param student_submission [StudentSubmission] The submission to process
  # @param document_content [String] The content of the document (real or mock)
  # @return [Boolean] True if the mocked process succeeded, false otherwise
  def mock_grading_process(student_submission, document_content = nil)
    # For demo purposes, randomly succeed or fail to show both paths
    if rand > 0.2 # 80% success rate
      # Use StatusManager for transitioning to completed state
      feedback = if document_content
                    "Successfully processed document with #{document_content.length} characters.\n\n" +
                    "This is mock feedback generated by the system. The submission looks good!"
      else
                    "This is mock feedback generated by the system. The submission looks good!"
      end

      StatusManager.transition_submission(
        student_submission,
        :completed,
        {
          feedback: feedback,
          graded_doc_id: "graded_#{student_submission.original_doc_id}"
        }
      )
      true
    else
      # Use StatusManager for transitioning to failed state
      StatusManager.transition_submission(
        student_submission,
        :failed,
        { feedback: "Submission processing failed. The system encountered an error while analyzing the document." }
      )
      false
    end
  end

  # Fetch document content from Google Drive
  #
  # @param google_drive_client [Google::Apis::DriveV3::DriveService] The Google Drive client
  # @param document_id [String] The ID of the document to fetch
  # @return [String] The content of the document
  # @raise [StandardError] If the document cannot be fetched or exported
  def fetch_document_content(google_drive_client, document_id)
    Rails.logger.info("Fetching document content for document ID: #{document_id}")

    begin
      # First, get the file metadata to determine the MIME type
      file = google_drive_client.get_file(document_id, fields: "id, name, mimeType")
      mime_type = file.mime_type

      # Handle different document types differently
      case mime_type
      when "application/vnd.google-apps.document"  # Google Docs
        # Export as plain text
        response = google_drive_client.export_file(document_id, "text/plain")
        content = response.string

      when "application/vnd.google-apps.spreadsheet"  # Google Sheets
        # Export as CSV
        response = google_drive_client.export_file(document_id, "text/csv")
        content = response.string

      when "application/pdf"  # PDF files
        # For PDFs, we'd ideally use a PDF extraction library
        # For now, let's return a placeholder
        content = "This is a PDF document that would need OCR or text extraction."

      when /^text\//  # Plain text files
        # Download directly
        response = google_drive_client.get_file(document_id, download_dest: StringIO.new)
        content = response.string

      else
        # For other file types, return a placeholder
        content = "Unsupported document type: #{mime_type}. Please submit a Google Doc, Sheet, or plain text file."
      end

      content
    rescue Google::Apis::ClientError => e
      Rails.logger.error("Google Drive client error: #{e.message}")
      raise StandardError, "Failed to access document: #{e.message}"
    rescue Google::Apis::ServerError => e
      Rails.logger.error("Google Drive server error: #{e.message}")
      raise StandardError, "Google Drive service unavailable: #{e.message}"
    rescue => e
      Rails.logger.error("Unexpected error fetching document: #{e.message}")
      raise StandardError, "Failed to fetch document content: #{e.message}"
    end
  end
end
