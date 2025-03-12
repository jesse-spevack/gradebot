require "test_helper"

class FormatGradingRubricJobTest < ActiveJob::TestCase
  setup do
    @grading_task = grading_tasks(:one)
  end

  test "formats grading rubric and broadcasts update" do
    # Mock the formatter service
    formatter = mock("GradingRubricFormatterService")
    GradingRubricFormatterService.stubs(:new).returns(formatter)
    formatter.expects(:format).with(@grading_task).returns(@grading_task)

    # Stub the reload
    GradingTask.any_instance.stubs(:reload).returns(@grading_task)

    # Mock RetryHandler to avoid complexity
    RetryHandler.stubs(:with_retry).yields

    # Mock the Turbo broadcast
    Turbo::StreamsChannel.expects(:broadcast_replace_to).with(
      "grading_task_#{@grading_task.id}",
      target: "grading_rubric_container_#{@grading_task.id}",
      partial: "grading_tasks/grading_rubric_container",
      locals: { grading_task: @grading_task }
    )

    # Perform the job
    FormatGradingRubricJob.perform_now(@grading_task.id)
  end

  test "handles non-existent grading task gracefully" do
    # No expectations on formatter or broadcast since it should return early
    FormatGradingRubricJob.perform_now(999999)
    # Test passes if no error is raised
  end
end
