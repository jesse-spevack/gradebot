require "test_helper"

class GradingOrchestratorTest < ActiveSupport::TestCase
  setup do
    # Create mock objects instead of using fixtures
    @submission = mock("StudentSubmission")
    @document_content = "This is a test document with content to grade."
    @grading_task = mock("GradingTask")
    @user = mock("User")

    # Set up the relationships
    @submission.stubs(:grading_task).returns(@grading_task)
    @submission.stubs(:original_doc_id).returns("test_doc_123")
    @submission.stubs(:id).returns(123)
    @grading_task.stubs(:user).returns(@user)
    @grading_task.stubs(:assignment_prompt).returns("Write an essay about climate change.")
    @grading_task.stubs(:grading_rubric).returns("Content: 40%, Structure: 30%, Grammar: 30%")

    # Create orchestrator
    @orchestrator = GradingOrchestrator.new(
      submission: @submission,
      document_content: @document_content
    )
  end

  test "initializes with submission and document content" do
    # Verify
    assert_equal @submission, @orchestrator.instance_variable_get(:@submission)
    assert_equal @document_content, @orchestrator.instance_variable_get(:@document_content)
    assert_equal @grading_task, @orchestrator.instance_variable_get(:@grading_task)
  end

  test "successfully grades submission" do
    # Setup - Create a successful mock result
    mock_result = mock("GradingResult")
    mock_result.stubs(:error).returns(nil)
    mock_result.stubs(:feedback).returns("Great job on your essay!")
    mock_result.stubs(:strengths).returns([ "Good analysis", "Clear structure" ])
    mock_result.stubs(:opportunities).returns([ "Add more examples", "Improve conclusion" ])
    mock_result.stubs(:overall_grade).returns("A")
    mock_result.stubs(:rubric_scores).returns({ "Content" => 38, "Structure" => 29, "Grammar" => 28 })

    # Mock the grading service
    grading_service = mock("GradingService")
    GradingService.stubs(:new).returns(grading_service)
    grading_service.expects(:grade_submission).with(
      @document_content,
      @grading_task.assignment_prompt,
      @grading_task.grading_rubric,
      @submission,
      @user
    ).returns(mock_result)

    # Exercise
    result = @orchestrator.grade

    # Verify
    assert_equal mock_result, result
  end

  test "raises error when grading result contains an error" do
    # Setup - Create a result with an error
    mock_result = mock("GradingResult")
    mock_result.stubs(:error).returns("Failed to process submission due to invalid content.")
    # Stubs for logging methods
    mock_result.stubs(:feedback).returns("Error feedback")
    mock_result.stubs(:strengths).returns([])
    mock_result.stubs(:opportunities).returns([])
    mock_result.stubs(:overall_grade).returns(nil)
    mock_result.stubs(:rubric_scores).returns({})

    # Mock the grading service
    grading_service = mock("GradingService")
    GradingService.stubs(:new).returns(grading_service)
    grading_service.expects(:grade_submission).returns(mock_result)

    # Stub logger methods to avoid real logging
    Rails.logger.stubs(:debug)
    Rails.logger.stubs(:error)

    # Exercise & Verify
    assert_raises(StandardError) do
      @orchestrator.grade
    end
  end

  test "logs grading result details" do
    # Setup - Create a successful mock result
    mock_result = mock("GradingResult")
    mock_result.stubs(:error).returns(nil)
    mock_result.stubs(:feedback).returns("Great job on your essay!")
    mock_result.stubs(:strengths).returns([ "Good analysis", "Clear structure" ])
    mock_result.stubs(:opportunities).returns([ "Add more examples", "Improve conclusion" ])
    mock_result.stubs(:overall_grade).returns("A")
    mock_result.stubs(:rubric_scores).returns({ "Content" => 38, "Structure" => 29, "Grammar" => 28 })

    # Mock the grading service
    grading_service = mock("GradingService")
    GradingService.stubs(:new).returns(grading_service)
    grading_service.expects(:grade_submission).returns(mock_result)

    # Expectations for debug logging
    Rails.logger.expects(:debug).with("GradingOrchestrator: Received result from GradingService")
    Rails.logger.expects(:debug).with("GradingOrchestrator: Result error: nil")
    Rails.logger.expects(:debug).with(regexp_matches(/GradingOrchestrator: Result feedback/))
    Rails.logger.expects(:debug).with(regexp_matches(/GradingOrchestrator: Result strengths/))
    Rails.logger.expects(:debug).with(regexp_matches(/GradingOrchestrator: Result opportunities/))
    Rails.logger.expects(:debug).with(regexp_matches(/GradingOrchestrator: Result overall_grade/))
    Rails.logger.expects(:debug).with(regexp_matches(/GradingOrchestrator: Result rubric_scores/))

    # Exercise
    @orchestrator.grade
  end

  test "handles errors from grading service" do
    # Setup
    grading_service = mock("GradingService")
    GradingService.stubs(:new).returns(grading_service)
    grading_service.expects(:grade_submission).raises(StandardError.new("Grading service error"))

    # Exercise & Verify
    assert_raises(StandardError) do
      @orchestrator.grade
    end
  end
end
