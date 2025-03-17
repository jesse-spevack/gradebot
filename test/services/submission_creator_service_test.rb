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

    # Setup expectations for submission creation
    @documents.each do |doc|
      submission = mock("StudentSubmission")
      submission.stubs(:id).returns(rand(1000))

      StudentSubmission.expects(:create!).with(
        grading_task: @grading_task,
        original_doc_id: doc[:id],
        status: :pending,
        metadata: { doc_type: doc[:mime_type] }
      ).returns(submission)

      # No longer expect job enqueuing here - it's handled by the GradingTask state machine
    end

    # Exercise
    result = service.create_submissions

    # Verify
    assert_equal 2, result
  end

  test "handles errors during submission creation" do
    # Setup
    service = SubmissionCreatorService.new(@grading_task, @documents)

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

    # Mock logger to capture error
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

    # Only expect 2 submissions to be created (for the documents)
    document_count = 0
    mixed_documents.each do |doc|
      if doc[:mime_type].include?("document") || doc[:mime_type].include?("spreadsheet")
        submission = mock("StudentSubmission")
        submission.stubs(:id).returns(rand(1000))

        StudentSubmission.expects(:create!).with(
          grading_task: @grading_task,
          original_doc_id: doc[:id],
          status: :pending,
          metadata: { doc_type: doc[:mime_type] }
        ).returns(submission)

        # No longer expect job enqueuing here
        document_count += 1
      end
    end

    # Exercise
    result = service.create_submissions

    # Verify
    assert_equal 2, result
  end
end
