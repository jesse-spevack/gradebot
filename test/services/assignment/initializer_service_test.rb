# frozen_string_literal: true

require "test_helper"

class Assignment::InitializerServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @assignment_params = {
      title: "New Essay",
      subject: "English",
      grade_level: "10",
      feedback_tone: "neutral/objective",
      instructions: "Write an essay about the importance of testing.",
      description: "This is a description of the assignment."
    }
    @document_data = [
      { google_doc_id: "doc1", title: "Essay Doc 1", url: "url1" },
      { google_doc_id: "doc2", title: "Essay Doc 2", url: "url2" }
    ]
    @input_data = Assignment::InitializerService::Input.new(
      current_user: @user,
      assignment_params: @assignment_params,
      document_data: @document_data
    )

    # Mock created selected documents that the bulk service would return/create
    @created_selected_docs = [
      SelectedDocument.new(id: 101, assignment_id: 1, google_doc_id: "doc1", title: "Essay Doc 1", url: "url1"),
      SelectedDocument.new(id: 102, assignment_id: 1, google_doc_id: "doc2", title: "Essay Doc 2", url: "url2")
    ]
  end

  test "#call successfully creates assignment, selected docs, student works, and enqueues job" do
    # Setup: Mock dependencies
    # Keep job mock
    AssignmentProcessingJob.expects(:perform_later).with(instance_of(String)).once

    # Exercise: Call the service
    service = Assignment::InitializerService.new(input: @input_data)

    # Capture counts before
    assignment_count_before = Assignment.count
    selected_doc_count_before = SelectedDocument.count
    student_work_count_before = StudentWork.count

    # Call the service
    result_assignment = service.call

    # Capture counts after
    assignment_count_after = Assignment.count
    selected_doc_count_after = SelectedDocument.count
    student_work_count_after = StudentWork.count

    # Verify: Check the results
    # Verify counts changed correctly
    assert_equal assignment_count_before + 1, assignment_count_after, "Assignment count should increase by 1"
    assert_equal selected_doc_count_before + 2, selected_doc_count_after, "SelectedDocument count should increase by 2"
    assert_equal student_work_count_before + 2, student_work_count_after, "StudentWork count should increase by 2"

    # Verify returned object and its state
    assert_instance_of Assignment, result_assignment
    assert result_assignment.persisted?
    assert_equal @assignment_params[:title], result_assignment.title
    assert_equal @user, result_assignment.user

    # Verify associations (optional, as sub-services handle this)
    assert_equal 2, result_assignment.selected_documents.count
    assert_equal 2, result_assignment.student_works.count
  end

  test "#call returns false and rolls back when assignment is invalid" do
    # Setup: Invalid assignment params (missing title)
    invalid_params = @assignment_params.except(:title)
    invalid_input = Assignment::InitializerService::Input.new(
      current_user: @user,
      assignment_params: invalid_params,
      document_data: @document_data
    )
    service = Assignment::InitializerService.new(input: invalid_input)

    # Expect job NOT to be called
    AssignmentProcessingJob.expects(:perform_later).never

    # Exercise & Verify: No records created, returns false
    assert_no_difference [ "Assignment.count", "SelectedDocument.count", "StudentWork.count" ] do
      result = service.call
      assert_equal false, result, "Service should return false on failure"
    end
  end

  # TODO: Add tests for failure scenarios (e.g., sub-service fails)
end
