require "test_helper"

class DocumentFetcherServiceTest < ActiveSupport::TestCase
  setup do
    # Create mock objects instead of using fixtures
    @user = mock("User")
    @grading_task = mock("GradingTask")
    @submission = mock("StudentSubmission")

    # Set up the relationships
    @submission.stubs(:grading_task).returns(@grading_task)
    @submission.stubs(:original_doc_id).returns("test_doc_123")
    @grading_task.stubs(:user).returns(@user)
    @submission.stubs(:id).returns(123)

    # Create a mock drive client
    @mock_client = mock("Google::Apis::DriveV3::DriveService")

    # Mock the token service to return our mock client
    TokenService.any_instance.stubs(:create_google_drive_client).returns(@mock_client)
  end

  test "initializes with a submission" do
    # Setup
    service = DocumentFetcherService.new(@submission)

    # Verify - check that we can access the submission through the service
    assert_equal @submission, service.instance_variable_get(:@submission)
    assert_equal @user, service.instance_variable_get(:@user)
  end

  test "fetches Google Doc content correctly" do
    # Setup
    service = DocumentFetcherService.new(@submission)
    doc_id = "test_doc_123"
    @user.stubs(:id).returns(456)

    # Mock file metadata for a Google Doc
    file = mock("file")
    file.stubs(:mime_type).returns("application/vnd.google-apps.document")
    @mock_client.stubs(:get_file).with(doc_id, fields: "id, name, mimeType").returns(file)

    # Mock the export functionality - must stubs string_io outputs rather than yields
    string_io = StringIO.new("This is a Google Doc content")
    StringIO.stubs(:new).returns(string_io)
    @mock_client.stubs(:export_file).with(doc_id, "text/plain", download_dest: anything).returns(nil)

    # Exercise
    content = nil
    assert_nothing_raised do
      content = service.fetch
    end

    # Verify
    assert_not_nil content
  end

  test "fetches Google Sheet content correctly" do
    # Setup
    service = DocumentFetcherService.new(@submission)
    doc_id = "test_sheet_123"
    @submission.stubs(:original_doc_id).returns(doc_id)
    @user.stubs(:id).returns(456)

    # Mock file metadata for a Google Sheet
    file = mock("file")
    file.stubs(:mime_type).returns("application/vnd.google-apps.spreadsheet")
    @mock_client.stubs(:get_file).with(doc_id, fields: "id, name, mimeType").returns(file)

    # Mock the export functionality
    string_io = StringIO.new("column1,column2\nvalue1,value2")
    StringIO.stubs(:new).returns(string_io)
    @mock_client.stubs(:export_file).with(doc_id, "text/csv", download_dest: anything).returns(nil)

    # Exercise
    content = nil
    assert_nothing_raised do
      content = service.fetch
    end

    # Verify
    assert_not_nil content
  end

  test "handles plain text files correctly" do
    # Setup
    service = DocumentFetcherService.new(@submission)
    doc_id = "test_text_123"
    @submission.stubs(:original_doc_id).returns(doc_id)
    @user.stubs(:id).returns(456)

    # Mock file metadata for a text file
    file = mock("file")
    file.stubs(:mime_type).returns("text/plain")
    @mock_client.stubs(:get_file).with(doc_id, fields: "id, name, mimeType").returns(file)

    # Mock the download functionality
    string_io = StringIO.new("This is plain text content")
    StringIO.stubs(:new).returns(string_io)
    @mock_client.stubs(:get_file).with(doc_id, download_dest: anything).returns(nil)

    # Exercise
    content = nil
    assert_nothing_raised do
      content = service.fetch
    end

    # Verify
    assert_not_nil content
  end

  test "handles token errors correctly" do
    # Setup
    service = DocumentFetcherService.new(@submission)
    @user.stubs(:id).returns(456)
    TokenService.any_instance.stubs(:create_google_drive_client).raises(TokenService::TokenError, "Token expired")

    # Exercise & Verify
    assert_raises(StandardError) do
      service.fetch
    end
  end

  test "handles Google API client errors correctly" do
    # Setup
    service = DocumentFetcherService.new(@submission)
    doc_id = "test_doc_123"
    @submission.stubs(:original_doc_id).returns(doc_id)

    # Mock Google API client error
    @mock_client.stubs(:get_file).with(doc_id, fields: "id, name, mimeType").raises(Google::Apis::ClientError.new("File not found"))

    # Exercise & Verify
    assert_raises(StandardError) do
      service.fetch
    end
  end

  test "handles Google API server errors correctly" do
    # Setup
    service = DocumentFetcherService.new(@submission)
    doc_id = "test_doc_123"
    @submission.stubs(:original_doc_id).returns(doc_id)

    # Mock Google API server error
    @mock_client.stubs(:get_file).with(doc_id, fields: "id, name, mimeType").raises(Google::Apis::ServerError.new("Server unavailable"))

    # Exercise & Verify
    assert_raises(StandardError) do
      service.fetch
    end
  end
end
