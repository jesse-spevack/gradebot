# frozen_string_literal: true

class DocumentContentFetcherService
  attr_reader :document_id, :google_drive_client

  def initialize(document_id:, google_drive_client:)
    @document_id = document_id
    @google_drive_client = google_drive_client
  end

  def fetch
    begin
      # TODO - run this in console to see what is going wrong.
      # Unexpected error fetching document: NoMethodError - undefined method `get_file' for #<GetGoogleDriveClientForStudentSubmission:0x000000010b25c590 @input_parameters={:student_submission=>#<StudentSubmission id: 204, grading_task_id: 68, original_doc_id: "1UMEF_5RaHl7w8B7q432Ww9nYLQhw3K-ZdrgTvXYVAj0", status: "processing", feedback: nil, graded_doc_id: nil, created_at: "2025-03-22 03:58:56.997000000 +0000", updated_at: "2025-03-22 03:59:17.207853000 +0000", lock_version: 3, strengths: nil, opportunities: nil, overall_grade: nil, rubric_scores: nil, metadata: nil, first_attempted_at: "2025-03-22 03:59:17.206373000 +0000", attempt_count: 1, document_selection_id: nil>}, @errors=[], @student_submission=#<StudentSubmission id: 204, grading_task_id: 68, original_doc_id: "1UMEF_5RaHl7w8B7q432Ww9nYLQhw3K-ZdrgTvXYVAj0", status: "processing", feedback: nil, graded_doc_id: nil, created_at: "2025-03-22 03:58:56.997000000 +0000", updated_at: "2025-03-22 03:59:17.207853000 +0000", lock_version: 3, strengths: nil, opportunities: nil, overall_grade: nil, rubric_scores: nil, metadata: nil, first_attempted_at: "2025-03-22 03:59:17.206373000 +0000", attempt_count: 1, document_selection_id: nil>, @result=#<Google::Apis::DriveV3::DriveService:0x000000010f05f0b8 @root_url_template="https://www.$UNIVERSE_DOMAIN$/", @universe_domain="googleapis.com", @root_url="https://www.googleapis.com/", @base_path="drive/v3/", @client_name="google-apis-drive_v3", @client_version="0.61.0", @upload_path="upload/drive/v3/", @batch_path="batch/drive/v3", @client_options=#<struct Google::Apis::ClientOptions application_name="unknown", application_version="0.0.0", proxy_url=nil, open_timeout_sec=nil, read_timeout_sec=nil, send_timeout_sec=nil, log_http_requests=false, transparent_gzip_decompression=true>, @request_options=#<struct Google::Apis::RequestOptions authorization="ya29.a0AeXRPp7mZfoqXKAmtM90j6EU96_9aNxrDGP6CXrcjdIGsBpAlSb0NF6kf92KyQG9mRVt-9IugHRMGoEM-0oYJbh3iYfMLS-BNdD1ZFWPoUhxLzto0SZKVIEPmYUtHcfY5ZBbgbTaIB3V_W24Dy5qxGFrAp1VX0FXioSReh2gBwaCgYKAXESARESFQHGX2MiDHvzBzuu_pVsFhie59ad4w0177", retries=0, max_elapsed_time=900, base_interval=1, max_interval=60, multiplier=2, header=nil, normalize_unicode=false, skip_serialization=false, skip_deserialization=false, api_format_version=nil, use_opencensus=true, quota_project=nil, query=nil, add_invocation_id_header=false, upload_chunk_size=104857600>>>
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
