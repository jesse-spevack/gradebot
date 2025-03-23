# frozen_string_literal: true

require "test_helper"

class FormatGradingRubricJobTest < ActiveJob::TestCase
  setup do
    @grading_task = grading_tasks(:one)
  end

  test "formats grading rubric" do
    # Set the grading task to the correct state
    @grading_task.update_column(:status, :rubric_processing)

    # Mock the formatter service
    mock_formatter = Minitest::Mock.new
    mock_formatter.expect :format, @grading_task, [ @grading_task ]

    # Stub the formatter class
    GradingTask::GradingRubricFormatterService.stub :new, mock_formatter do
      # Stub the broadcast to avoid actual broadcasts
      Turbo::StreamsChannel.stub :broadcast_replace_to, nil do
        # Perform the job
        FormatGradingRubricJob.perform_now(@grading_task.id)
      end
    end

    # Verify the mock
    mock_formatter.verify
  end

  test "handles errors gracefully" do
    error = StandardError.new("Test error")

    # Mock the formatter service to raise an error
    GradingTask::GradingRubricFormatterService.stub :new, -> { raise error } do
      # Stub Rails logger to verify it's called
      Rails.logger.stub :error, nil do
        # Perform the job - should not raise an error
        assert_nothing_raised do
          FormatGradingRubricJob.perform_now(@grading_task.id)
        end
      end
    end
  end

  test "does nothing if grading task not found" do
    # Perform the job with a non-existent ID
    result = FormatGradingRubricJob.perform_now(999999)

    # Should return nil
    assert_nil result
  end

  test "handles optimistic locking errors" do
    # Create a mock formatter that returns the grading task
    mock_formatter = Object.new
    def mock_formatter.format(grading_task)
      # Simulate another process updating the record
      grading_task.increment!(:lock_version)

      # Return the grading task
      grading_task
    end

    # Stub the formatter class
    GradingTask::GradingRubricFormatterService.stub :new, mock_formatter do
      # Stub the broadcast to avoid actual broadcasts
      Turbo::StreamsChannel.stub :broadcast_replace_to, nil do
        # Perform the job - should not raise an error
        assert_nothing_raised do
          FormatGradingRubricJob.perform_now(@grading_task.id)
        end
      end
    end
  end
end
