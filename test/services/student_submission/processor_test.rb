require "test_helper"

class StudentSubmission::ProcessorTest < ActiveSupport::TestCase
  test "it processes a student submission" do
    student_submission = student_submissions(:pending_submission)

    assert(student_submission.pending?)
    assert_empty(student_submission.feedback)
    assert_nil(student_submission.strengths)
    assert_nil(student_submission.opportunities)
    assert_nil(student_submission.overall_grade)
    assert_nil(student_submission.rubric_scores)
    assert_nil(student_submission.metadata)
    assert_nil(student_submission.first_attempted_at)
    assert_equal(0, student_submission.attempt_count)

    grading_result = GradingResponse.new(
      feedback: "Test feedback",
      strengths: [ "Strength 1", "Strength 2" ],
      opportunities: [ "Opportunity 1", "Opportunity 2" ],
      overall_grade: 85,
      rubric_scores: { "Rubric 1" => 90, "Rubric 2" => 80 },
      summary: "Test summary",
      question: "Test question"
    )

    StudentSubmission::DocumentContentFetcherService.stubs(:fetch)
      .with(student_submission: student_submission)
      .returns("Test document content")

    Grading::GradingOrchestrator.stubs(:grade)
      .with(
        student_submission: student_submission,
        document_content: "Test document content"
      )
      .returns(grading_result)

    # result = StudentSubmission::Processor.process(student_submission: student_submission)
    service = StudentSubmission::Processor.new(student_submission: student_submission)
    result = service.execute

    assert(result.completed?)
    assert(result.first_attempted_at)
    assert_equal(grading_result.feedback, result.feedback)
    assert(grading_result.strengths.each { |strength| result.strengths.include?(strength) })
    assert(grading_result.opportunities.each { |opportunity| result.opportunities.include?(opportunity) })
    assert_equal(grading_result.overall_grade.to_s, result.overall_grade)
    assert_equal(grading_result.rubric_scores.to_json, result.rubric_scores)
    assert_equal(1, result.attempt_count)
  end
end
