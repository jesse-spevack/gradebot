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
      folder_id: "abc123folder",
      folder_name: "Climate Change Essays"
    }
  end

  test "enqueues job when grading task is created" do
    # Setup
    assert_enqueued_with(job: GradingTaskJob) do
      # Exercise
      GradingTask.create!(@grading_task_attributes)
    end
  end

  test "job calls ProcessGradingTaskCommand with task id" do
    # Setup
    grading_task = GradingTask.create!(@grading_task_attributes)
    command_mock = Minitest::Mock.new
    command_mock.expect(:call, command_mock)
    command_mock.expect(:failure?, false)

    # Exercise
    ProcessGradingTaskCommand.stub(:new, ->(grading_task_id:) {
      assert_equal grading_task.id, grading_task_id
      command_mock
    }) do
      GradingTaskJob.perform_now(grading_task.id)
    end

    # Verify
    assert_mock command_mock
  end

  test "logs error if command fails" do
    # Setup
    grading_task = GradingTask.create!(@grading_task_attributes)
    command_mock = Minitest::Mock.new
    command_mock.expect(:call, command_mock)
    command_mock.expect(:failure?, true)
    command_mock.expect(:errors, [ "Failed to process grading task" ])

    # Exercise & Verify
    ProcessGradingTaskCommand.stub(:new, ->(**) { command_mock }) do
      assert_logged(level: :error, message: /GradingTaskJob failed/) do
        GradingTaskJob.perform_now(grading_task.id)
      end
    end
  end

  private

  # Helper to verify log messages
  def assert_logged(level:, message:)
    old_logger = Rails.logger
    begin
      mock_logger = Minitest::Mock.new
      mock_logger.expect(level, nil) do |msg, _|
        assert_match message, msg
        true
      end
      Rails.logger = mock_logger
      yield
      assert_mock mock_logger
    ensure
      Rails.logger = old_logger
    end
  end
end
