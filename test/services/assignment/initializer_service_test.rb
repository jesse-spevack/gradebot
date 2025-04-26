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
      { "title" => "doc1", "googleDocId" => "doc1", "url" => "url1" },
      { "title" => "doc2", "googleDocId" => "doc2", "url" => "url2" }
    ]
    @input_data = Assignment::InitializerServiceInput.new(
      current_user: @user,
      assignment_params: @assignment_params,
      document_data: @document_data
    )
  end

  test "#call successfully creates assignment, selected docs, student works, and enqueues job" do
    AssignmentProcessingJob.expects(:perform_later).with(instance_of(Integer)).once

    # Capture counts before
    assignment_count_before = Assignment.count
    selected_doc_count_before = SelectedDocument.count
    student_work_count_before = StudentWork.count

    # Exercise: Call the service
    assignment = Assignment::InitializerService.call(input: @input_data)

    # Capture counts after
    assignment_count_after = Assignment.count
    selected_doc_count_after = SelectedDocument.count
    student_work_count_after = StudentWork.count

    assert_equal assignment_count_before + 1, assignment_count_after, "Assignment count should increase by 1"
    assert_equal selected_doc_count_before + 2, selected_doc_count_after, "SelectedDocument count should increase by 2"
    assert_equal student_work_count_before + 2, student_work_count_after, "StudentWork count should increase by 2"

    # Verify returned object and its state
    assert_instance_of Assignment, assignment
    assert assignment.persisted?
    assert_equal @assignment_params[:title], assignment.title
    assert_equal @user, assignment.user

    # Verify associations (optional, as sub-services handle this)
    assert_equal 2, assignment.selected_documents.count
    assert_equal 2, assignment.student_works.count
  end

  test "#call returns false and rolls back when assignment is invalid" do
    # Setup: Invalid assignment params (missing title)
    invalid_params = @assignment_params.except(:title)
    invalid_input = Assignment::InitializerServiceInput.new(
      current_user: @user,
      assignment_params: invalid_params,
      document_data: @document_data
    )

    # Expect job NOT to be called
    AssignmentProcessingJob.expects(:perform_later).never

    # Exercise & Verify: No records created, returns false
    assert_no_difference [ "Assignment.count", "SelectedDocument.count", "StudentWork.count" ] do
      result = Assignment::InitializerService.call(input: invalid_input)
      assert_equal false, result, "Service should return false on failure"
    end
  end
end
