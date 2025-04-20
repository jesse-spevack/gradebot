require "test_helper"

class DocumentDataCollectionTest < ActiveSupport::TestCase
  setup do
    @valid_documents = [
      { "id" => "doc1", "name" => "Student 1 Document", "url" => "https://docs.google.com/document/d/doc1" },
      { "id" => "doc2", "name" => "Student 2 Document", "url" => "https://docs.google.com/document/d/doc2" }
    ]
  end

  test "is valid with valid documents" do
    collection = DocumentDataCollection.new(@valid_documents)

    assert collection.valid?
    assert_equal 2, collection.count
  end

  test "is invalid with empty collection" do
    collection = DocumentDataCollection.new([])

    assert_not collection.valid?
    assert_includes collection.errors[:base], "At least one document must be selected"
  end

  test "is invalid with too many documents" do
    # Create an array with more than MAX_DOCUMENTS items
    many_docs = (1..DocumentDataCollection::MAX_DOCUMENTS + 1).map do |i|
      { "id" => "doc#{i}", "name" => "Student #{i} Document", "url" => "https://docs.google.com/document/d/doc#{i}" }
    end

    collection = DocumentDataCollection.new(many_docs)

    assert_not collection.valid?
    assert_includes collection.errors[:base], "Maximum of #{DocumentDataCollection::MAX_DOCUMENTS} documents allowed, but #{many_docs.count} were provided"
  end

  test "is invalid with invalid document items" do
    invalid_docs = [
      { "id" => "doc1", "name" => "Student 1 Document", "url" => "https://docs.google.com/document/d/doc1" },
      { "id" => "doc2", "name" => "", "url" => "https://docs.google.com/document/d/doc2" } # Missing name
    ]

    collection = DocumentDataCollection.new(invalid_docs)

    assert_not collection.valid?
    assert_includes collection.errors[:base], "Document 2: Name can't be blank"
  end

  test "from_json parses json string" do
    json_string = '[{"id":"doc1","name":"Student 1 Document","url":"https://docs.google.com/document/d/doc1"}]'

    collection = DocumentDataCollection.from_json(json_string)

    assert collection.valid?
    assert_equal 1, collection.count
    assert_equal "doc1", collection.first.id
  end

  test "from_json handles invalid json" do
    collection = DocumentDataCollection.from_json("not json")

    assert_equal 0, collection.count
    assert_not collection.valid?
  end

  test "to_selection_params returns array of params" do
    collection = DocumentDataCollection.new(@valid_documents)

    params = collection.to_selection_params(123)

    assert_equal 2, params.length
    assert_equal 123, params[0][:grading_task_id]
    assert_equal "doc1", params[0][:document_id]
  end

  test "array access works" do
    collection = DocumentDataCollection.new(@valid_documents)

    assert_equal "doc1", collection[0].id
    assert_equal "doc2", collection[1].id
    assert_nil collection[2]
  end
end
