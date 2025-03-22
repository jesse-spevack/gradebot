# frozen_string_literal: true

class DocumentContentFetcherService
  attr_reader :document_id, :google_drive_client

  def initialize(document_id:, google_drive_client:)
    @document_id = document_id
    @google_drive_client = google_drive_client
  end

  def fetch
    begin
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
        Rails.logger.info("Successfully fetched document content (#{content.length} characters)")
      else
        # For other file types, return a placeholder
        Rails.logger.info("Unsupported file type: #{mime_type}")
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
      Rails.logger.error("Unexpected error fetching document: #{e.class.name} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) # Log the full backtrace for debugging
      raise StandardError, "Failed to fetch document content: #{e.message}"
    end
  end
end
