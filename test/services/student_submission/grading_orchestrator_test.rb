require "test_helper"

class Grading::GradingOrchestratorTest < ActiveSupport::TestCase
  test "orchestrates the grading process of a student submission" do
    student_submission = student_submissions(:pending_submission)
    document_content = "This is a test document"
    grading_task = student_submission.grading_task
    grading_service = mock
    Grading::GradingService.stubs(:new).returns(grading_service)

    grading_service.expects(:grade_submission).with(
      document_content,
      grading_task.assignment_prompt,
      grading_task.grading_rubric,
      student_submission,
      grading_task.user
    ).returns(
      GradingResult.new(
        feedback: "Test feedback",
        strengths: [ "Test strength 1", "Test strength 2" ],
        opportunities: [ "Test opportunity 1", "Test opportunity 2" ],
        overall_grade: "A",
        scores: { "Content" => 90, "Organization" => 80, "Language" => 70 }
      )
    )

    orchestrator = Grading::GradingOrchestrator.new(
      student_submission: student_submission,
      document_content: document_content
    )

    orchestrator.grade
  end
end
