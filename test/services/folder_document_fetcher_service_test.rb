require "test_helper"

class FolderDocumentFetcherServiceTest < ActiveSupport::TestCase
  setup do
    @access_token = "mock_access_token"
    @folder_id = "mock_folder_id"

    # Create mock GoogleDriveService
    @mock_drive_service = mock("GoogleDriveService")
    GoogleDriveService.stubs(:new).with(@access_token).returns(@mock_drive_service)
  end

  test "initializes with access token and folder ID" do
    # Setup
    service = FolderDocumentFetcherService.new(@access_token, @folder_id)

    # Verify
    assert_equal @access_token, service.instance_variable_get(:@access_token)
    assert_equal @folder_id, service.instance_variable_get(:@folder_id)
  end

  test "successfully fetches documents from folder" do
    # Setup
    mock_documents = [
      { id: "doc1", name: "Document 1", mime_type: "application/vnd.google-apps.document" },
      { id: "doc2", name: "Document 2", mime_type: "application/vnd.google-apps.document" }
    ]

    @mock_drive_service.expects(:list_files_in_folder).with(@folder_id).returns(mock_documents)

    service = FolderDocumentFetcherService.new(@access_token, @folder_id)

    # Exercise
    documents = service.fetch

    # Verify
    assert_equal 2, documents.length
    assert_equal "doc1", documents[0][:id]
    assert_equal "Document 1", documents[0][:name]
    assert_equal "doc2", documents[1][:id]
  end

  test "handles Google Drive service errors" do
    # Setup
    @mock_drive_service.expects(:list_files_in_folder).with(@folder_id)
      .raises(GoogleDriveService::Error.new("Failed to access folder"))

    service = FolderDocumentFetcherService.new(@access_token, @folder_id)

    # Exercise & Verify
    assert_raises(StandardError) do
      service.fetch
    end
  end

  test "handles empty folder gracefully" do
    # Setup
    @mock_drive_service.expects(:list_files_in_folder).with(@folder_id).returns([])

    service = FolderDocumentFetcherService.new(@access_token, @folder_id)

    # Exercise
    documents = service.fetch

    # Verify
    assert_empty documents
  end
end
