require "test_helper"

class SelectedDocumentTest < ActiveSupport::TestCase
  def setup
    @assignment = assignments(:valid_assignment)
    @selected_doc = selected_documents(:doc_1) # Use fixture
  end

  test "invalid without assignment" do
    doc = SelectedDocument.new(google_doc_id: "doc1", title: "Title 1", url: "url1")
    assert_not doc.valid?
    assert_not_empty doc.errors[:assignment]
  end

  test "invalid without google_doc_id" do
    doc = SelectedDocument.new(assignment: @assignment, title: "Title 1", url: "url1")
    assert_not doc.valid?
    assert_not_empty doc.errors[:google_doc_id]
  end

  test "invalid without title" do
    doc = SelectedDocument.new(assignment: @assignment, google_doc_id: "new_doc_id", url: "url1")
    assert_not doc.valid?
    assert_not_empty doc.errors[:title]
  end

  test "invalid without url" do
    doc = SelectedDocument.new(assignment: @assignment, google_doc_id: "new_doc_id", title: "Title 1")
    assert_not doc.valid?
    assert_not_empty doc.errors[:url]
  end

  test "valid selected document fixture" do
    assert @selected_doc.valid?, "Fixture doc_1 should be valid"
    assert selected_documents(:doc_2).valid?, "Fixture doc_2 should be valid"
    assert selected_documents(:doc_3).valid?, "Fixture doc_3 should be valid"
  end

  test "belongs to assignment" do
    # Use fixture
    assert_respond_to @selected_doc, :assignment
    assert_equal @assignment, @selected_doc.assignment
  end

  test "has prefix id" do
    # Use fixture
    assert_respond_to @selected_doc, :prefix_id
    assert @selected_doc.prefix_id.starts_with?("sd_")
  end
end
