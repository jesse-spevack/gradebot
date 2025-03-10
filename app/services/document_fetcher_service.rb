# frozen_string_literal: true

# Service to fetch document content from Google Drive
class DocumentFetcherService
  # @param submission [StudentSubmission] The submission to fetch content for
  def initialize(submission)
    @submission = submission
    @user = submission.grading_task.user
  end

  # Fetches document content from Google Drive
  # @return [String] The content of the document
  # @raise [StandardError] If the document cannot be fetched
  def fetch
    Rails.logger.info("Fetching document content for submission #{@submission.id} (doc ID: #{@submission.original_doc_id})")

    token_service = TokenService.new(@user)
    google_drive_client = token_service.create_google_drive_client

    fetch_document_content(google_drive_client, @submission.original_doc_id)
  rescue TokenService::TokenError => e
    Rails.logger.error("Token error for user #{@user.id}: #{e.message}")
    raise StandardError, "Failed to get access token: #{e.message}"
  end

  private

  # Fetch document content from Google Drive based on MIME type
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
end
