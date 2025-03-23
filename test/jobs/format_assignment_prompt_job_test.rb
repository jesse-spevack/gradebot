# frozen_string_literal: true

require "test_helper"

class FormatAssignmentPromptJobTest < ActiveJob::TestCase
  setup do
    @grading_task = grading_tasks(:one)
    # Disable actual broadcasts for all tests
    @original_broadcast_method = Turbo::StreamsChannel.method(:broadcast_replace_to)
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*args| }
  end

  teardown do
    # Restore the original broadcast method
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to, @original_broadcast_method)
  end

  test "formats assignment prompt" do
    # Set the grading task to the correct initial state
    @grading_task.update!(status: :assignment_processing)

    # Mock the formatter service
    mock_formatter = Minitest::Mock.new
    mock_formatter.expect :format, @grading_task, [ @grading_task ]

    # Stub the formatter class
    GradingTask::AssignmentPromptFormatterService.stub :new, mock_formatter do
      # Perform the job
      FormatAssignmentPromptJob.perform_now(@grading_task.id)
    end

    # Verify the mock
    mock_formatter.verify

    # Verify the state transition
    @grading_task.reload
    assert_equal "rubric_processing", @grading_task.status
  end

  test "transitions state after processing" do
    # Set the grading task to the correct initial state
    @grading_task.update!(status: :assignment_processing)

    # Mock the formatter
    formatter = mock
    formatter.stubs(:format).returns(@grading_task)
    GradingTask::AssignmentPromptFormatterService.stubs(:new).returns(formatter)

    # Perform the job
    FormatAssignmentPromptJob.perform_now(@grading_task.id)

    # Reload the grading task
    @grading_task.reload

    # Check that the state transitioned
    assert_equal "rubric_processing", @grading_task.status
  end

  test "handles errors gracefully" do
    # Set the grading task to the correct initial state
    @grading_task.update!(status: :assignment_processing)

    error = StandardError.new("Test error")

    # Mock the formatter service to raise an error
    GradingTask::AssignmentPromptFormatterService.stub :new, -> { raise error } do
      # Stub Rails logger to verify it's called
      Rails.logger.stub :error, nil do
        # Perform the job - should not raise an error
        assert_nothing_raised do
          FormatAssignmentPromptJob.perform_now(@grading_task.id)
        end
      end
    end

    # Verify the state transition to failed
    @grading_task.reload
    assert_equal "failed", @grading_task.status
  end

  test "does nothing if grading task not found" do
    # Perform the job with a non-existent ID
    result = FormatAssignmentPromptJob.perform_now(999999)

    # Should return nil
    assert_nil result
  end

  test "does nothing if grading task is in wrong state" do
    # Set the grading task to an incorrect state
    @grading_task.update!(status: :created)

    # Mock the formatter service
    mock_formatter = Minitest::Mock.new
    # This should not be called

    # Stub the formatter class
    GradingTask::AssignmentPromptFormatterService.stub :new, mock_formatter do
      # Perform the job
      FormatAssignmentPromptJob.perform_now(@grading_task.id)
    end

    # Verify the state did not change
    @grading_task.reload
    assert_equal "created", @grading_task.status
  end
end
