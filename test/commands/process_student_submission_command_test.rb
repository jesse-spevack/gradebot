require "test_helper"
require "minitest/mock"

class ProcessStudentSubmissionCommandTest < ActiveJob::TestCase
  test "it processes a student submission" do
    grading_task = grading_tasks(:one)
    student_submission = StudentSubmission.create!(
      grading_task: grading_task,
      original_doc_id: "test_doc_123",
      status: :pending
    )

    assert(student_submission.pending?)
    assert_nil(student_submission.feedback)
    assert_nil(student_submission.strengths)
    assert_nil(student_submission.opportunities)
    assert_nil(student_submission.overall_grade)
    assert_nil(student_submission.rubric_scores)
    assert_nil(student_submission.metadata)
    assert_nil(student_submission.first_attempted_at)
    assert_equal(0, student_submission.attempt_count)

    get_google_drive_client_for_student_submission = mock
    google_drive_client = mock

    GetGoogleDriveClientForStudentSubmission.stubs(:new)
      .with(
        student_submission: student_submission
      ).returns(get_google_drive_client_for_student_submission)

    get_google_drive_client_for_student_submission.stubs(:call).returns(google_drive_client)

    test_document_content = "Test document content"
    document_content_fetcher = mock

    DocumentContentFetcherService.stubs(:new)
      .with(
        google_doc_id: student_submission.original_doc_id,
        google_drive_client: google_drive_client
      ).returns(document_content_fetcher)
    document_content_fetcher.stubs(:fetch).returns(test_document_content)

    orchestrator = mock
    GradingOrchestrator.stubs(:new)
      .with(
        student_submission: student_submission,
        document_content: test_document_content
      ).returns(orchestrator)

    grading_result = GradingResponse.new(
      feedback: "Test feedback",
      strengths: [ "Strength 1", "Strength 2" ],
      opportunities: [ "Opportunity 1", "Opportunity 2" ],
      overall_grade: 85,
      rubric_scores: { "Rubric 1" => 90, "Rubric 2" => 80 },
      summary: "Test summary",
      question: "Test question"
    )
    orchestrator.stubs(:grade).returns(grading_result)

    command = ProcessStudentSubmissionCommand.new(student_submission: student_submission)
    command.call
    result = command.result

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
