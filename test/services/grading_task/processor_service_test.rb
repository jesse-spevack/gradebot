require "test_helper"

class GradingTask::ProcessorServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:teacher)
    @grading_task = grading_tasks(:three)

    # Ensure the grading task has a rubric and assignment prompt
    @rubric = rubrics(:essay_rubric)
    @assignment_prompt = assignment_prompts(:essay_analysis_for_grading_task_three)
  end

  test "processes a grading task successfully" do
    # Mock the Rubric::GeneratorService to avoid actual LLM calls
    Rubric::GeneratorService.expects(:generate).with(
      assignment_prompt: @assignment_prompt,
      grading_task: @grading_task,
      rubric: @rubric
    ).returns(@rubric)

    # Process the grading task
    result = GradingTask::ProcessorService.process(@grading_task.id)

    # Verify the result
    assert_equal @grading_task.id, result.id
    assert_equal "processing", result.status
    assert_equal "complete", result.rubric.status
  end

  test "handles a missing grading task" do
    # Try to process a non-existent grading task
    result = GradingTask::ProcessorService.process(999999)

    # Verify the result
    assert_nil result
  end

  test "handles errors during rubric generation" do
    # Mock the Rubric::GeneratorService to raise an error
    Rubric::GeneratorService.expects(:generate).raises(StandardError.new("Test error"))

    # Verify that the error is propagated
    assert_raises(GradingTask::ProcessorService::ProcessingError) do
      GradingTask::ProcessorService.process(@grading_task.id)
    end

    @grading_task.reload
    # Verify that the rubric status is set to failed
    assert_equal "failed", @grading_task.rubric.status
    assert_equal "failed", @grading_task.status
  end

  test "only processes a rubric if it's in pending status" do
    # Set the rubric to already be complete
    @rubric.update!(status: :complete)

    # Rubric::GeneratorService should not be called
    Rubric::GeneratorService.expects(:generate).never

    # Process the grading task
    result = GradingTask::ProcessorService.process(@grading_task.id)

    # Verify the result
    assert_equal @grading_task.id, result.id
  end
end
