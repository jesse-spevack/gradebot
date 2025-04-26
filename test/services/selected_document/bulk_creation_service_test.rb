# frozen_string_literal: true

require "test_helper"

class SelectedDocument::BulkCreationServiceTest < ActiveSupport::TestCase
  setup do
    @assignment = assignments(:valid_assignment)
    @valid_documents = [
      OpenStruct.new(google_doc_id: "doc1", url: "https://docs.google.com/document/d/doc1", title: "Essay 1"),
      OpenStruct.new(google_doc_id: "doc2", url: "https://docs.google.com/document/d/doc2", title: "Essay 2")
    ]
  end

  test "creates selected documents for valid input" do
    assert_difference "SelectedDocument.count", 2 do
      SelectedDocument::BulkCreationService.new(assignment: @assignment, documents_data: @valid_documents).call
    end
    doc = SelectedDocument.find_by(google_doc_id: "doc1")
    assert_equal @assignment, doc.assignment
    assert_equal "Essay 1", doc.title
    assert_equal "https://docs.google.com/document/d/doc1", doc.url
  end

  test "raises error if more than 35 documents" do
    too_many = Array.new(36) { |i| OpenStruct.new(google_doc_id: "doc#{i}", url: "https://docs.google.com/document/d/doc#{i}", title: "Essay #{i}") }
    assert_raises(SelectedDocument::BulkCreationService::TooManyDocumentsError) do
      SelectedDocument::BulkCreationService.new(assignment: @assignment, documents_data: too_many).call
    end
  end
end
