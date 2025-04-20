require "test_helper"

class DocumentSelection::BulkCreationServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:teacher)
    @grading_task = grading_tasks(:two)
    @document_data = [
      { "id" => "doc1", "name" => "Student 1 Essay.docx", "url" => "https://docs.google.com/document/d/doc1" },
      { "id" => "doc2", "name" => "Student 2 Essay.docx", "url" => "https://docs.google.com/document/d/doc2" },
      { "id" => "doc3", "name" => "Student 3 Essay.docx", "url" => "https://docs.google.com/document/d/doc3" }
    ]
  end

  test "creates multiple document selections successfully" do
    document_selections = DocumentSelection::BulkCreationService.call(
      grading_task: @grading_task,
      document_data: @document_data
    )

    assert_equal 3, document_selections.size
    document_ids = document_selections.map(&:document_id)
    assert_includes document_ids, "doc1"
    assert_includes document_ids, "doc2"
    assert_includes document_ids, "doc3"

    # All should belong to the same grading task
    document_selections.each do |ds|
      assert_equal @grading_task.id, ds.grading_task_id
    end
  end

  test "returns empty array when document_data is empty" do
    error = assert_raises(DocumentSelection::BulkCreationService::Error) do
      DocumentSelection::BulkCreationService.call(
        grading_task: @grading_task,
        document_data: []
      )
    end

    assert_match /Document data is required/, error.message
  end

  test "raises error when grading task is missing" do
    error = assert_raises(DocumentSelection::BulkCreationService::Error) do
      DocumentSelection::BulkCreationService.call(
        grading_task: nil,
        document_data: @document_data
      )
    end

    assert_match /Grading task is required/, error.message
  end

  test "raises error when document_data is not an array" do
    error = assert_raises(DocumentSelection::BulkCreationService::Error) do
      DocumentSelection::BulkCreationService.call(
        grading_task: @grading_task,
        document_data: "not an array"
      )
    end

    assert_match /Document data must be an array/, error.message
  end

  test "enforces maximum document limit" do
    max_plus_one = DocumentSelection::BulkCreationService::MAX_DOCUMENTS + 1
    too_many_docs = max_plus_one.times.map do |i|
      { "id" => "doc#{i}", "name" => "Student #{i} Essay.docx", "url" => "https://docs.google.com/document/d/doc#{i}" }
    end

    error = assert_raises(DocumentSelection::BulkCreationService::Error) do
      DocumentSelection::BulkCreationService.call(
        grading_task: @grading_task,
        document_data: too_many_docs
      )
    end

    assert_match /Maximum of #{DocumentSelection::BulkCreationService::MAX_DOCUMENTS} documents allowed/, error.message
  end

  test "handles large number of documents efficiently" do
    large_document_data = 30.times.map do |i|
      { "id" => "doc#{i}", "name" => "Student #{i} Essay.docx", "url" => "https://docs.google.com/document/d/doc#{i}" }
    end

    start_time = Time.current
    document_selections = DocumentSelection::BulkCreationService.call(
      grading_task: @grading_task,
      document_data: large_document_data
    )
    end_time = Time.current

    assert_equal 30, document_selections.size
    assert (end_time - start_time) < 0.5, "Bulk creation took too long: #{end_time - start_time} seconds"
  end
end
