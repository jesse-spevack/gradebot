# frozen_string_literal: true

require "test_helper"

class StudentWork::BulkCreationServiceTest < ActiveSupport::TestCase
  setup do
    # Setup fixtures for assignment and selected documents
    @assignment = assignments(:valid_assignment)
    @selected_doc1 = selected_documents(:doc_1)
    @selected_doc2 = selected_documents(:doc_2)
    @selected_documents = [ @selected_doc1, @selected_doc2 ]
  end

  test "creates student work records for valid selected documents using insert_all" do
    # Setup: Ensure no pre-existing work for these selected docs to avoid conflicts
    StudentWork.where(selected_document: @selected_documents).destroy_all
    assert StudentWork.where(selected_document: @selected_documents).empty?, "Pre-existing StudentWork should be deleted"

    # Exercise
    assert_difference "StudentWork.count", @selected_documents.size do
      service = StudentWork::BulkCreationService.new(assignment: @assignment, selected_documents: @selected_documents)
      assert service.call, "Service call should return true"
    end

    # Verify
    created_works = StudentWork.where(selected_document: @selected_documents).order(:selected_document_id)

    assert_equal 2, created_works.size
    assert_equal @selected_doc1, created_works[0].selected_document
    assert_equal @assignment, created_works[0].assignment
    assert created_works[0].pending?, "Status should be pending for work related to doc1"

    assert_equal @selected_doc2, created_works[1].selected_document
    assert_equal @assignment, created_works[1].assignment
    assert created_works[1].pending?, "Status should be pending for work related to doc2"
  end
end
