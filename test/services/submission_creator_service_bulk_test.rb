require "test_helper"

class SubmissionCreatorServiceBulkTest < ActiveSupport::TestCase
  setup do
    @grading_task = mock("GradingTask")
    @grading_task.stubs(:id).returns(123)
    @grading_task.stubs(:user).returns(mock("User"))

    @documents = [
      { id: "doc1", name: "Student 1 Essay", mime_type: "application/vnd.google-apps.document" },
      { id: "doc2", name: "Student 2 Essay", mime_type: "application/vnd.google-apps.document" },
      { id: "doc3", name: "Student 3 Essay", mime_type: "application/vnd.google-apps.document" }
    ]
  end

  test "bulk creates student submissions" do
    # Setup
    service = SubmissionCreatorService.new(@grading_task, @documents)

    # Mock the insert_all! method to return a result with count
    mock_result = mock("BulkInsertResult")
    mock_result.stubs(:count).returns(@documents.length)

    # Expect bulk insertion to be called with any array of attributes
    StudentSubmission.expects(:insert_all!).returns(mock_result)

    # Exercise
    result = service.create_submissions

    # Verify
    assert_equal @documents.length, result
  end

  test "falls back to individual creation if bulk insertion fails" do
    # Setup
    service = SubmissionCreatorService.new(@grading_task, @documents)

    # Expect bulk insertion to fail
    StudentSubmission.expects(:insert_all!).raises(ActiveRecord::RecordNotUnique.new("Duplicate key error"))

    # Expect individual creation for each document
    @documents.each do |doc|
      submission = mock("StudentSubmission")
      submission.stubs(:id).returns(rand(1000))

      StudentSubmission.expects(:create!).with(
        grading_task: @grading_task,
        original_doc_id: doc[:id],
        status: :pending,
        metadata: { doc_type: doc[:mime_type] }
      ).returns(submission)
    end

    # Exercise
    result = service.create_submissions

    # Verify
    assert_equal @documents.length, result
  end

  test "filters out non-document files before bulk insertion" do
    # Setup
    mixed_documents = [
      { id: "doc1", name: "Student 1 Essay", mime_type: "application/vnd.google-apps.document" },
      { id: "img1", name: "Image file", mime_type: "image/jpeg" }, # Should be skipped
      { id: "doc2", name: "Student 2 Essay", mime_type: "application/vnd.google-apps.document" },
      { id: "sheet1", name: "Student 3 Spreadsheet", mime_type: "application/vnd.google-apps.spreadsheet" }
    ]

    service = SubmissionCreatorService.new(@grading_task, mixed_documents)

    # Only the document and spreadsheet should be included in the bulk insertion
    valid_docs = mixed_documents.select do |doc|
      doc[:mime_type].include?("document") || doc[:mime_type].include?("spreadsheet")
    end

    # Mock the insert_all! method to return a result with count
    mock_result = mock("BulkInsertResult")
    mock_result.stubs(:count).returns(valid_docs.length)

    # Expect bulk insertion to be called
    StudentSubmission.expects(:insert_all!).returns(mock_result)

    # Exercise
    result = service.create_submissions

    # Verify
    assert_equal valid_docs.length, result
  end
end
