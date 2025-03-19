require "test_helper"

class SubmissionCreatorServiceTest < ActiveSupport::TestCase
  setup do
    @grading_task = mock("GradingTask")
    @grading_task.stubs(:id).returns(123)
    @grading_task.stubs(:user).returns(mock("User"))

    @documents = [
      { id: "doc1", name: "Student 1 Essay", mime_type: "application/vnd.google-apps.document" },
      { id: "doc2", name: "Student 2 Essay", mime_type: "application/vnd.google-apps.document" }
    ]
  end

  test "initializes with grading task and documents" do
    # Setup
    service = SubmissionCreatorService.new(@grading_task, @documents)

    # Verify
    assert_equal @grading_task, service.instance_variable_get(:@grading_task)
    assert_equal @documents, service.instance_variable_get(:@documents)
  end

  test "returns 0 for empty documents array" do
    # Setup
    service = SubmissionCreatorService.new(@grading_task, [])

    # Exercise
    result = service.create_submissions

    # Verify
    assert_equal 0, result
  end

  test "creates student submissions for each document" do
    # Setup
    service = SubmissionCreatorService.new(@grading_task, @documents)

    # Mock the insert_all! method to return a result with count
    mock_result = mock("BulkInsertResult")
    mock_result.stubs(:count).returns(@documents.length)

    # Expect bulk insertion to be called
    StudentSubmission.expects(:insert_all!).returns(mock_result)

    # Exercise
    result = service.create_submissions

    # Verify
    assert_equal 2, result
  end

  test "handles errors during submission creation" do
    # Setup
    service = SubmissionCreatorService.new(@grading_task, @documents)

    # Expect bulk insertion to fail
    StudentSubmission.expects(:insert_all!).raises(ActiveRecord::RecordNotUnique.new("Duplicate key error"))

    # First document creates successfully
    submission1 = mock("StudentSubmission")
    submission1.stubs(:id).returns(101)
    StudentSubmission.expects(:create!).with(
      grading_task: @grading_task,
      original_doc_id: @documents[0][:id],
      status: :pending,
      metadata: { doc_type: @documents[0][:mime_type] }
    ).returns(submission1)

    # No longer expect job enqueuing here

    # Second document creation fails
    StudentSubmission.expects(:create!).with(
      grading_task: @grading_task,
      original_doc_id: @documents[1][:id],
      status: :pending,
      metadata: { doc_type: @documents[1][:mime_type] }
    ).raises(ActiveRecord::RecordInvalid.new(StudentSubmission.new))

    # Mock logger to capture errors
    Rails.logger.expects(:error).with(includes("Failed to bulk create submissions"))
    Rails.logger.expects(:error).with(includes("Failed to create submission"))

    # Exercise
    result = service.create_submissions

    # Verify - should still count the successful submission
    assert_equal 1, result
  end

  test "skips non-document files" do
    # Setup
    mixed_documents = [
      { id: "doc1", name: "Student 1 Essay", mime_type: "application/vnd.google-apps.document" },
      { id: "img1", name: "Image file", mime_type: "image/jpeg" }, # Should be skipped
      { id: "doc2", name: "Student 2 Essay", mime_type: "application/vnd.google-apps.document" }
    ]

    service = SubmissionCreatorService.new(@grading_task, mixed_documents)

    # Only the documents should be included in the bulk insertion (2 out of 3)
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
    assert_equal 2, result
  end
end
