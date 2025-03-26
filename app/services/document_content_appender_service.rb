# frozen_string_literal: true

class DocumentContentAppenderService
  FEEDBACK_HEADER = "🎯 Feedback:"
  HEADER_STYLE = "HEADING_1"
  CONTENT_STYLE = "HEADING_6"

  attr_reader :document_id, :google_docs_client

  def initialize(document_id:, google_docs_client:)
    @document_id = document_id
    @google_docs_client = google_docs_client
  end

  def append(content)
    Rails.logger.info("Starting append operation for document: #{document_id}")

    begin
      start_index = get_document_length

      header_start, header_end = insert_header(start_index, FEEDBACK_HEADER)
      format_header(header_start, header_end)

      content_start_index = header_end + 1 # Start after the header
      content_start, content_end = insert_content(content_start_index, content)
      format_content(content_start, content_end)

      Rails.logger.info("Successfully appended content to document: #{document_id}")
    rescue Google::Apis::ClientError => e
      Rails.logger.error("Failed to append content to document: #{e.message}")
      Rails.logger.debug("Error details: #{e.backtrace.join("\n")}")
      raise e
    rescue StandardError => e
      Rails.logger.error("Unexpected error appending to document: #{e.message}")
      Rails.logger.debug("Error details: #{e.backtrace.join("\n")}")
      raise e
    end
  end

  private

  def get_document_length
    Rails.logger.debug("Retrieving document: #{document_id}")
    document = google_docs_client.get_document(document_id)
    document_length = document.body.content.last.end_index
    start_index = document_length - 1
    Rails.logger.debug("Document length: #{document_length}, using start index: #{start_index}")
    start_index
  end

  def insert_header(start_index, header_text)
    Rails.logger.debug("Inserting header at index #{start_index}")
    insert_request = create_text_insertion_request(start_index, "\n#{header_text}")
    execute_batch_update([ insert_request ])

    # Calculate header indices
    header_start_index = start_index + 1 # Start after the newline
    header_end_index = header_start_index + header_text.length
    Rails.logger.debug("Header inserted from index #{header_start_index} to #{header_end_index}")

    [ header_start_index, header_end_index ]
  end

  def format_header(start_index, end_index)
    Rails.logger.debug("Formatting header from index #{start_index} to #{end_index}")
    format_request = create_format_request(start_index, end_index, HEADER_STYLE)
    execute_batch_update([ format_request ])
    Rails.logger.debug("Header formatting complete")
  end

  def insert_content(start_index, content)
    Rails.logger.debug("Inserting content at index #{start_index}")
    append_request = create_text_insertion_request(start_index, "\n#{content}")
    execute_batch_update([ append_request ])

    # Calculate content indices
    content_start_index = start_index + 1 # Start after the newline
    content_end_index = content_start_index + content.length
    Rails.logger.debug("Content inserted from index #{content_start_index} to #{content_end_index}")

    [ content_start_index, content_end_index ]
  end

  def format_content(start_index, end_index)
    Rails.logger.debug("Formatting content from index #{start_index} to #{end_index}")
    format_request = create_format_request(start_index, end_index, CONTENT_STYLE)
    execute_batch_update([ format_request ])
    Rails.logger.debug("Content formatting complete")
  end

  def create_text_insertion_request(index, text)
    {
      insert_text: {
        end_of_segment_location: { index: index },
        text: text
      }
    }
  end

  def create_format_request(start_index, end_index, style_type)
    {
      update_paragraph_style: {
        range: { start_index: start_index, end_index: end_index },
        paragraph_style: { named_style_type: style_type },
        fields: "namedStyleType"
      }
    }
  end

  def execute_batch_update(requests)
    Rails.logger.debug("Executing batch update with #{requests.size} request(s)")
    result = google_docs_client.batch_update_document(
      document_id,
      Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: requests)
    )
    Rails.logger.debug("Batch update successful")
    result
  end
end
