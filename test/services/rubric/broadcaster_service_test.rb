# frozen_string_literal: true

require "test_helper"

class Rubric::BroadcasterServiceTest < ActiveSupport::TestCase
  test "broadcasts rubric updates to the correct channel and targets" do
    # Setup
    rubric = rubrics(:empty_rubric)

    # Mock the broadcast_replace_to method to verify it's called correctly
    Turbo::StreamsChannel.expects(:broadcast_replace_to)
      .with(
        "rubric_#{rubric.id}",
        {
          target: "rubric_container_#{rubric.id}",
          partial: "grading_tasks/rubric_card",
          locals: { rubric: rubric }
        }
      )
      .returns(true)

    Turbo::StreamsChannel.expects(:broadcast_replace_to)
      .with(
        "rubric_#{rubric.id}",
        {
          target: "rubric_status_badge_#{rubric.id}",
          partial: "shared/status_badge",
          locals: {
            status: "processing",
            size: "sm",
            hide_processing_spinner: false
          }
        }
      )
      .returns(true)

    # Exercise
    result = Rubric::BroadcasterService.broadcast(rubric)

    # Verify
    assert result, "Broadcast should return true on success"
  end

  test "handles and logs errors during broadcast" do
    # Setup
    rubric = rubrics(:empty_rubric)

    # Mock an error during broadcast
    Turbo::StreamsChannel.expects(:broadcast_replace_to)
      .raises(StandardError.new("Broadcast error"))

    # Exercise & Verify
    logs = capture_logs do
      result = Rubric::BroadcasterService.broadcast(rubric)
      refute result, "Broadcast should return false on error"
    end

    assert_match(/Failed to broadcast rubric update: Broadcast error/, logs)
  end

  private

  def capture_logs
    old_logger = Rails.logger
    string_io = StringIO.new
    Rails.logger = Logger.new(string_io)

    yield

    string_io.string
  ensure
    Rails.logger = old_logger
  end
end
