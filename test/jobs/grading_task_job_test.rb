require "test_helper"

class GradingTaskJobTest < ActiveJob::TestCase
  # Setup
  setup do
    @grading_task = grading_tasks(:three)
  end

  test "it calls the GradingTask::ProcessorService with the grading task id" do
    GradingTask::ProcessorService.expects(:process).with(@grading_task.id)

    GradingTaskJob.perform_now(@grading_task.id)
  end
end
