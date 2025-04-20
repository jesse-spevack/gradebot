require "test_helper"

class StudentSubmission::BulkCreationServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:teacher)
    @grading_task = grading_tasks(:two)
    @document_selections = []

    # Create 3 document selections for testing
    3.times do |i|
      @document_selections << DocumentSelection.create!(
        grading_task: @grading_task,
        document_id: "doc#{i}",
        name: "Student #{i} Essay.docx",
        url: "https://docs.google.com/document/d/doc#{i}"
      )
    end
  end

  test "creates multiple student submissions successfully" do
    student_submissions = StudentSubmission::BulkCreationService.call(
      grading_task: @grading_task,
      document_selections: @document_selections
    )

    assert_equal 3, student_submissions.size

    # All should be associated with the correct grading task
    student_submissions.each do |submission|
      assert_equal @grading_task.id, submission.grading_task_id
      assert_includes @document_selections.map(&:id), submission.document_selection_id
      assert_equal "pending", submission.status
    end

    # Each document selection should have exactly one student submission
    @document_selections.each do |ds|
      assert_equal 1, student_submissions.count { |s| s.document_selection_id == ds.id }
    end
  end

  test "raises error when grading task is missing" do
    error = assert_raises(StudentSubmission::BulkCreationService::Error) do
      StudentSubmission::BulkCreationService.call(
        grading_task: nil,
        document_selections: @document_selections
      )
    end

    assert_match /Grading task is required/, error.message
  end

  test "raises error when document selections are nil" do
    error = assert_raises(StudentSubmission::BulkCreationService::Error) do
      StudentSubmission::BulkCreationService.call(
        grading_task: @grading_task,
        document_selections: nil
      )
    end

    assert_match /Document selections are required/, error.message
  end

  test "raises error when document selections are empty" do
    error = assert_raises(StudentSubmission::BulkCreationService::Error) do
      StudentSubmission::BulkCreationService.call(
        grading_task: @grading_task,
        document_selections: []
      )
    end

    assert_match /At least one document selection is required/, error.message
  end

  test "handles large number of document selections efficiently" do
    # First clean up existing document selections to avoid test interference
    DocumentSelection.where(grading_task: @grading_task).destroy_all

    # Create a large number of document selections
    large_document_selections = []
    30.times do |i|
      large_document_selections << DocumentSelection.create!(
        grading_task: @grading_task,
        document_id: "doc#{i}",
        name: "Student #{i} Essay.docx",
        url: "https://docs.google.com/document/d/doc#{i}"
      )
    end

    start_time = Time.current
    student_submissions = StudentSubmission::BulkCreationService.call(
      grading_task: @grading_task,
      document_selections: large_document_selections
    )
    end_time = Time.current

    assert_equal 30, student_submissions.size
    assert (end_time - start_time) < 0.5, "Bulk creation took too long: #{end_time - start_time} seconds"
  end
end
