require "test_helper"

class DocumentContentFetcherServiceTest < ActiveSupport::TestCase
  test "fetches Google Doc content correctly" do
    document_id = "test_doc_123"
    google_drive_client = mock
    mock_result = mock
    mock_string_io = mock

    service = DocumentContentFetcherService.new(
      document_id: document_id,
      google_drive_client: google_drive_client
    )

    google_drive_client.expects(:get_file).with(document_id, fields: "id, name, mimeType").returns(mock_result)
    mock_result.expects(:mime_type).returns("application/vnd.google-apps.document")
    StringIO.stubs(:new).returns(mock_string_io)
    google_drive_client.expects(:export_file).with(document_id, "text/plain", download_dest: mock_string_io)
    mock_string_io.expects(:string).returns("Test document content")

    assert_equal "Test document content", service.fetch
  end
end
