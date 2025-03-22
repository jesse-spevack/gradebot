require "test_helper"

class CreateStudentSubmissionsCommandTest < ActiveSupport::TestCase
  test "it creates student submissions" do
    StudentSubmission.destroy_all
    grading_task = grading_tasks(:one)
    document_selections = DocumentSelection.where(grading_task: grading_task)

    command = CreateStudentSubmissionsCommand.call(
      grading_task: grading_task,
      document_selections: document_selections
    )

    assert command.success?
    assert_equal document_selections.length, StudentSubmission.where(grading_task: grading_task).count
  end
end
