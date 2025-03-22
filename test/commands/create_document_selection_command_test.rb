require "test_helper"

class CreateDocumentSelectionCommandTest < ActiveSupport::TestCase
  setup do
    @grading_task = grading_tasks(:one)
    @document_data = [
      { "id" => "doc1", "name" => "Document 1", "url" => "https://docs.google.com/document/d/doc1" },
      { "id" => "doc2", "name" => "Document 2", "url" => "https://docs.google.com/document/d/doc2" }
    ]
  end

  test "successfully creates document selections" do
    # Setup - count existing document selections
    initial_count = DocumentSelection.count

    # Exercise
    command = CreateDocumentSelectionCommand.new(
      grading_task: @grading_task,
      document_data: @document_data
    )

    command.call
    result = command.result

    # Verify
    assert_not command.failure?
    assert_equal 2, result.size

    # Verify document selection attributes
    assert_equal "doc1", result.first.document_id
    assert_equal "Document 1", result.first.name
    assert_equal "https://docs.google.com/document/d/doc1", result.first.url
    assert_equal @grading_task, result.first.grading_task

    assert_equal "doc2", result.last.document_id
    assert_equal "Document 2", result.last.name
    assert_equal "https://docs.google.com/document/d/doc2", result.last.url
    assert_equal @grading_task, result.last.grading_task
  end

  test "returns empty array when document_data is empty" do
    # Setup
    initial_count = DocumentSelection.count

    # Exercise
    command = CreateDocumentSelectionCommand.new(
      grading_task: @grading_task,
      document_data: []
    )
    command.call

    # Verify
    assert_not command.failure?
    assert_equal [], command.result
    assert_equal initial_count, DocumentSelection.count
  end

  test "returns empty array when document_data is nil" do
    # Setup
    initial_count = DocumentSelection.count

    # Exercise
    command = CreateDocumentSelectionCommand.new(
      grading_task: @grading_task,
      document_data: nil
    )
    command.call

    # Verify
    assert_not command.failure?
    assert_equal [], command.result
    assert_equal initial_count, DocumentSelection.count
  end

  test "handles database errors gracefully" do
    # Setup - create an invalid document data entry that will cause a database error
    invalid_document_data = [ { "id" => nil, "name" => "Invalid Document", "url" => "https://example.com" } ]

    # Exercise
    command = CreateDocumentSelectionCommand.new(
      grading_task: @grading_task,
      document_data: invalid_document_data
    )
    command.call

    # Verify
    assert command.failure?
    assert_not_empty command.errors
  end
end
