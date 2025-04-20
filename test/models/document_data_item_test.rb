require "test_helper"

class DocumentDataItemTest < ActiveSupport::TestCase
  test "is valid with all required fields" do
    item = DocumentDataItem.new(
      id: "doc1",
      name: "Student 1 Document",
      url: "https://docs.google.com/document/d/doc1"
    )

    assert item.valid?
  end

  test "is invalid without required fields" do
    item = DocumentDataItem.new

    assert_not item.valid?
    assert_includes item.errors[:id], "can't be blank"
    assert_includes item.errors[:name], "can't be blank"
    assert_includes item.errors[:url], "can't be blank"
  end

  test "handles both string and symbol keys" do
    # String keys (like from JSON)
    item1 = DocumentDataItem.new(
      "id" => "doc1",
      "name" => "Student 1 Document",
      "url" => "https://docs.google.com/document/d/doc1"
    )

    assert item1.valid?
    assert_equal "doc1", item1.id

    # Symbol keys (like from Ruby)
    item2 = DocumentDataItem.new(
      id: "doc2",
      name: "Student 2 Document",
      url: "https://docs.google.com/document/d/doc2"
    )

    assert item2.valid?
    assert_equal "doc2", item2.id
  end

  test "to_selection_params returns hash for document selection" do
    item = DocumentDataItem.new(
      id: "doc1",
      name: "Student 1 Document",
      url: "https://docs.google.com/document/d/doc1"
    )

    params = item.to_selection_params(123)

    assert_equal 123, params[:grading_task_id]
    assert_equal "doc1", params[:document_id]
    assert_equal "Student 1 Document", params[:name]
    assert_equal "https://docs.google.com/document/d/doc1", params[:url]
  end
end
