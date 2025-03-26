require "test_helper"

class DocumentContentAppenderServiceTest < ActiveSupport::TestCase
  setup do
    @document_id = "test_doc_123"
    @content = "Test document content"

    # Mock document data
    @document_length = 101
    @start_index = @document_length - 1
    @header_start_index = @start_index + 1
    @header_end_index = @header_start_index + DocumentContentAppenderService::FEEDBACK_HEADER.length
    @content_start_index = @header_end_index + 1
    @content_paragraph_start_index = @content_start_index + 1
    @content_paragraph_end_index = @content_paragraph_start_index + @content.length
  end

  test "appends content to Google Doc correctly" do
    # Create mocks
    google_docs_client = mock("GoogleDocsClient")
    mock_result = mock("BatchUpdateResult")
    mock_document = mock("Document")
    mock_body = mock("DocumentBody")
    mock_content = mock("DocumentContent")

    # Setup document mock structure
    mock_content.expects(:end_index).returns(@document_length)
    mock_body.expects(:content).returns([ mock_content ])
    mock_document.expects(:body).returns(mock_body)

    # 1. Expect document retrieval
    google_docs_client.expects(:get_document).with(@document_id).returns(mock_document)

    # Allow any batch update calls with correct document ID
    google_docs_client.stubs(:batch_update_document).with do |doc_id, request|
      doc_id == @document_id &&
      request.is_a?(Google::Apis::DocsV1::BatchUpdateDocumentRequest) &&
      request.requests.is_a?(Array) &&
      request.requests.size == 1
    end.returns(mock_result)

    # Create service and call method
    service = DocumentContentAppenderService.new(
      document_id: @document_id,
      google_docs_client: google_docs_client
    )

    # The test
    service.append(@content)
  end

  test "appends header and content with correct formatting" do
    # Create a test double that records the requests
    recorded_requests = []

    google_docs_client = Object.new
    mock_document = mock("Document")
    mock_body = mock("DocumentBody")
    mock_content = mock("DocumentContent")
    mock_result = mock("BatchUpdateResult")

    # Setup document mock structure
    mock_content.stubs(:end_index).returns(@document_length)
    mock_body.stubs(:content).returns([ mock_content ])
    mock_document.stubs(:body).returns(mock_body)

    # Mock the Google Docs client methods
    def google_docs_client.get_document(document_id)
      @mock_document
    end

    def google_docs_client.batch_update_document(document_id, request)
      @recorded_requests << request.requests
      @mock_result
    end

    # Set instance variables
    google_docs_client.instance_variable_set(:@mock_document, mock_document)
    google_docs_client.instance_variable_set(:@recorded_requests, recorded_requests)
    google_docs_client.instance_variable_set(:@mock_result, mock_result)

    # Create service and call method
    service = DocumentContentAppenderService.new(
      document_id: @document_id,
      google_docs_client: google_docs_client
    )

    # Execute the method
    service.append(@content)

    # Verify that we recorded 4 separate requests
    assert_equal 4, recorded_requests.size

    # First request should be to insert header
    assert_equal 1, recorded_requests[0].size
    assert recorded_requests[0][0].key?(:insert_text)
    assert_equal "\n#{DocumentContentAppenderService::FEEDBACK_HEADER}", recorded_requests[0][0][:insert_text][:text]

    # Second request should be to format header with HEADING_1
    assert_equal 1, recorded_requests[1].size
    assert recorded_requests[1][0].key?(:update_paragraph_style)
    assert_equal DocumentContentAppenderService::HEADER_STYLE,
                 recorded_requests[1][0][:update_paragraph_style][:paragraph_style][:named_style_type]

    # Third request should be to insert content
    assert_equal 1, recorded_requests[2].size
    assert recorded_requests[2][0].key?(:insert_text)
    assert_equal "\n#{@content}", recorded_requests[2][0][:insert_text][:text]

    # Fourth request should be to format content with HEADING_6
    assert_equal 1, recorded_requests[3].size
    assert recorded_requests[3][0].key?(:update_paragraph_style)
    assert_equal DocumentContentAppenderService::CONTENT_STYLE,
                 recorded_requests[3][0][:update_paragraph_style][:paragraph_style][:named_style_type]
  end
end
