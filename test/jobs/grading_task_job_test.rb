require "test_helper"
require "minitest/mock"

class GradingTaskJobTest < ActiveJob::TestCase
  # Setup
  setup do
    @user = users(:teacher)
    @grading_task_attributes = {
      user: @user,
      assignment_prompt: "Write a 500 word essay about climate change.",
      grading_rubric: "Content: 40%, Structure: 30%, Grammar: 30%",
      status: "created"
    }
  end

  test "enqueues job when grading task is created" do
    assert_enqueued_with(job: GradingTaskJob) do
      GradingTask.create!(@grading_task_attributes)
    end
  end

  test "job calls ProcessGradingTaskCommand with task id" do
    grading_task = GradingTask.create!(@grading_task_attributes)

    command_mock = mock("ProcessGradingTaskCommand")
    command_mock.stubs(:call).returns(command_mock)
    command_mock.stubs(:failure?).returns(false)

    ProcessGradingTaskCommand.expects(:new).with(grading_task_id: grading_task.id).returns(command_mock)

    GradingTaskJob.perform_now(grading_task.id)
  end
end
