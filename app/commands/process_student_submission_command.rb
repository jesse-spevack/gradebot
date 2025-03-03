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

    begin
      # Log the start of grading
      Rails.logger.info("Starting to grade submission #{student_submission.id} for document #{student_submission.original_doc_id}")

      # Create a new GradingService instance
      grading_service = GradingService.new

      # Grade the submission
      result = grading_service.grade_submission(
        document_content,
        grading_task.assignment_prompt,
        grading_task.grading_rubric
      )

      # Add debugging to inspect the result object
      Rails.logger.debug("ProcessStudentSubmissionCommand: Received result from GradingService")
      Rails.logger.debug("ProcessStudentSubmissionCommand: Result error: #{result.error.inspect}")
      Rails.logger.debug("ProcessStudentSubmissionCommand: Result feedback: #{result.feedback.truncate(100)}")
      Rails.logger.debug("ProcessStudentSubmissionCommand: Result strengths: #{result.strengths.inspect}")
      Rails.logger.debug("ProcessStudentSubmissionCommand: Result opportunities: #{result.opportunities.inspect}")
      Rails.logger.debug("ProcessStudentSubmissionCommand: Result overall_grade: #{result.overall_grade.inspect}")
      Rails.logger.debug("ProcessStudentSubmissionCommand: Result rubric_scores: #{result.rubric_scores.inspect}")

      # Check if there was an error
      if result.error.present?
        Rails.logger.error("Grading error: #{result.error}")
        @errors << "Failed to grade submission: #{result.error}"

        # Transition to failed state
        StatusManager.transition_submission(
          student_submission,
          :failed,
          { feedback: "Grading failed: #{result.error.truncate(200)}" }
        )

        return false
      end

      # Log success
      Rails.logger.info("Successfully graded submission #{student_submission.id} with grade: #{result.overall_grade}")

      # Format attributes for display
      strengths_formatted = format_array_attribute(result.strengths)
      opportunities_formatted = format_array_attribute(result.opportunities)

      Rails.logger.debug("ProcessStudentSubmissionCommand: strengths_formatted: #{strengths_formatted.inspect}")
      Rails.logger.debug("ProcessStudentSubmissionCommand: opportunities_formatted: #{opportunities_formatted.inspect}")

      # Prepare attributes for status transition
      transition_attributes = {
        feedback: result.feedback,
        # Document generation is not implemented yet, so we're not including graded_doc_id
        # This can be added back once the document generation functionality is ready
        # graded_doc_id: generate_graded_document(student_submission, document_content, result),
        strengths: "- " + result.strengths.join("\n- "),
        opportunities: "- " + result.opportunities.join("\n- "),
        overall_grade: result.overall_grade,
        rubric_scores: result.rubric_scores.to_json,
        metadata: {
          doc_title: student_submission.document_title || "Untitled Document",
          processing_time: (Time.current - student_submission.updated_at).round(1),
          word_count: document_content.split(/\s+/).size
        }
      }

      Rails.logger.debug("ProcessStudentSubmissionCommand: Transition attributes: #{transition_attributes.inspect}")

      # If successful, transition the submission to "completed"
      StatusManager.transition_submission(
        student_submission,
        :completed,
        transition_attributes
      )

      true
    rescue ArgumentError => e
      if e.message.include?("wrong number of arguments")
        # Log detailed debugging information for this specific error
        error_message = "DEBUG: ArgumentError - #{e.message}"
        Rails.logger.error(error_message)
        Rails.logger.error("DEBUG: Backtrace: #{e.backtrace.first(10).join("\n")}")

        # Add to errors
        @errors << "Wrong number of arguments error: #{e.message}"

        # Transition to failed state with more detailed information
        StatusManager.transition_submission(
          student_submission,
          :failed,
          { feedback: "Failed to complete grading due to argument mismatch. The development team has been notified." }
        )

        false
      else
        # For other ArgumentErrors, just handle them like other StandardErrors
        error_message = "Error during grading: #{e.message}"
        Rails.logger.error(error_message)
        Rails.logger.error(e.backtrace.first(10).join("\n"))

        # Add to errors
        @errors << error_message

        # Transition to failed state
        StatusManager.transition_submission(
          student_submission,
          :failed,
          { feedback: "Failed to complete grading: #{e.message.truncate(150)}" }
        )

        false
      end
    rescue StandardError => e
      # Log the error with backtrace
      error_message = "Error during grading: #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error(e.backtrace.first(10).join("\n"))

      # Add to errors
      @errors << error_message

      # Transition to failed state
      StatusManager.transition_submission(
        student_submission,
        :failed,
        { feedback: "Failed to complete grading: #{e.message.truncate(150)}" }
      )

      false
    end
  end

  # Generate a placeholder for the graded document
  #
  # This is a temporary implementation that simply returns a consistent placeholder ID
  # since the real implementation for document generation appears to be missing.
  #
  # Note: This method is currently not being used, as graded_doc_id generation is disabled
  # in the grade_with_llm method. This stub is kept for future reference.
  #
  # @param student_submission [StudentSubmission] The submission to create a graded document for
  # @param document_content [String] The content of the original document
  # @param result [GradingResponse] The grading result
  # @return [String] A placeholder document ID
  def generate_graded_document(student_submission, document_content, result)
    # In the future, this would create a new document with feedback
    # For now, we'll just create a placeholder ID
    placeholder_id = "graded_#{student_submission.original_doc_id}"

    Rails.logger.info("Created placeholder graded document with ID: #{placeholder_id}")

    placeholder_id
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
      Rails.logger.info("Document MIME type: #{mime_type}")

      # Handle different document types differently
      case mime_type
      when "application/vnd.google-apps.document"  # Google Docs
        # Export as plain text using StringIO
        string_io = StringIO.new
        Rails.logger.info("Exporting Google Doc as plain text")
        google_drive_client.export_file(document_id, "text/plain", download_dest: string_io)
        content = string_io.string

      when "application/vnd.google-apps.spreadsheet"  # Google Sheets
        # Export as CSV using StringIO
        string_io = StringIO.new
        Rails.logger.info("Exporting Google Sheet as CSV")
        google_drive_client.export_file(document_id, "text/csv", download_dest: string_io)
        content = string_io.string

      when "application/pdf"  # PDF files
        # For PDFs, we'd ideally use a PDF extraction library
        # For now, let's return a placeholder
        Rails.logger.info("PDF detected - returning placeholder content")
        content = "This is a PDF document that would need OCR or text extraction."

      when /^text\//  # Plain text files
        # Download directly using StringIO
        string_io = StringIO.new
        Rails.logger.info("Downloading plain text file")
        google_drive_client.get_file(document_id, download_dest: string_io)
        content = string_io.string

      else
        # For other file types, return a placeholder
        Rails.logger.info("Unsupported file type: #{mime_type}")
        content = "Unsupported document type: #{mime_type}. Please submit a Google Doc, Sheet, or plain text file."
      end

      Rails.logger.info("Successfully fetched document content (#{content.length} characters)")
      content
    rescue Google::Apis::ClientError => e
      Rails.logger.error("Google Drive client error: #{e.message}")
      raise StandardError, "Failed to access document: #{e.message}"
    rescue Google::Apis::ServerError => e
      Rails.logger.error("Google Drive server error: #{e.message}")
      raise StandardError, "Google Drive service unavailable: #{e.message}"
    rescue => e
      Rails.logger.error("Unexpected error fetching document: #{e.class.name} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) # Log the full backtrace for debugging
      raise StandardError, "Failed to fetch document content: #{e.message}"
    end
  end

  # Helper method to format array attributes (strengths, opportunities) into a consistent format
  # @param attribute [Array, String] The attribute to format
  # @return [String] The formatted attribute
  private def format_array_attribute(attribute)
    Rails.logger.debug("ProcessStudentSubmissionCommand: format_array_attribute called with: #{attribute.inspect} (class: #{attribute.class})")

    result = case attribute
    when Array
      attribute.empty? ? "" : "- " + attribute.join("\n- ")
    when String
      attribute
    else
      attribute.to_s
    end

    Rails.logger.debug("ProcessStudentSubmissionCommand: format_array_attribute returning: #{result.inspect}")
    result
  end
end
