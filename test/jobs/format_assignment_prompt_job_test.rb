# frozen_string_literal: true

require "test_helper"

class FormatAssignmentPromptJobTest < ActiveJob::TestCase
  setup do
    @grading_task = grading_tasks(:one)
  end

  test "formats assignment prompt" do
    # Mock the formatter service
    mock_formatter = Minitest::Mock.new
    mock_formatter.expect :format, @grading_task, [ @grading_task ]

    # Stub the formatter class
    AssignmentPromptFormatterService.stub :new, mock_formatter do
      # Stub the broadcast to avoid actual broadcasts
      Turbo::StreamsChannel.stub :broadcast_replace_to, nil do
        # Perform the job
        FormatAssignmentPromptJob.perform_now(@grading_task.id)
      end
    end

    # Verify the mock
    mock_formatter.verify
  end

  test "handles errors gracefully" do
    error = StandardError.new("Test error")

    # Mock the formatter service to raise an error
    AssignmentPromptFormatterService.stub :new, -> { raise error } do
      # Stub Rails logger to verify it's called
      Rails.logger.stub :error, nil do
        # Perform the job - should not raise an error
        assert_nothing_raised do
          FormatAssignmentPromptJob.perform_now(@grading_task.id)
        end
      end
    end
  end

  test "does nothing if grading task not found" do
    # Perform the job with a non-existent ID
    result = FormatAssignmentPromptJob.perform_now(999999)

    # Should return nil
    assert_nil result
  end
end
