require "test_helper"

class CreateDocumentSelectionCommandTest < ActiveSupport::TestCase
  setup do
    DocumentSelection.destroy_all
    @grading_task = grading_tasks(:one)
    @document_data = [
      { "id" => "doc1", "name" => "Document 1", "url" => "https://docs.google.com/document/d/doc1" },
      { "id" => "doc2", "name" => "Document 2", "url" => "https://docs.google.com/document/d/doc2" }
    ]
  end

  test "successfully creates document selections" do
    command = CreateDocumentSelectionCommand.call(
      grading_task: @grading_task,
      document_data: @document_data
    )
    result = command.result

    refute command.failure?
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
    command = CreateDocumentSelectionCommand.call(
      grading_task: @grading_task,
      document_data: []
    )

    assert_not command.failure?
    assert_equal [], command.result
  end

  test "returns empty array when document_data is nil" do
    command = CreateDocumentSelectionCommand.new(
      grading_task: @grading_task,
      document_data: nil
    )
    command.call

    assert_not command.failure?
    assert_equal [], command.result
  end

  test "handles database errors gracefully" do
    invalid_document_data = [ { "id" => nil, "name" => "Invalid Document", "url" => "https://example.com" } ]

    command = CreateDocumentSelectionCommand.new(
      grading_task: @grading_task,
      document_data: invalid_document_data
    )
    command.call

    assert command.failure?
    assert_not_empty command.errors
  end
end
