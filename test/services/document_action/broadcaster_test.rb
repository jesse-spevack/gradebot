require "test_helper"

class DocumentAction::BroadcasterTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @student_submission = student_submissions(:completed_submission)
    @document_action = DocumentAction.create!(
      student_submission: @student_submission,
      action_type: :post_feedback,
      status: :pending
    )
  end

  test "broadcasts to document action channel" do
    # Verify a broadcast is sent to the document action channel
    assert_broadcasts("document_action_#{@document_action.id}", 1) do
      DocumentAction::Broadcaster.new(@document_action).broadcast_update
    end
  end

  test "broadcasts to student submission channel" do
    # Verify a broadcast is sent to the student submission channel
    assert_broadcasts("student_submission_#{@document_action.student_submission_id}", 1) do
      DocumentAction::Broadcaster.new(@document_action).broadcast_update
    end
  end

  test "initializes with document action" do
    # Setup & Exercise
    broadcaster = DocumentAction::Broadcaster.new(@document_action)

    # Verify
    assert_equal @document_action, broadcaster.document_action
  end

  test "broadcast_update sends broadcasts to both channels" do
    # Verify that both channels receive a broadcast in a single call
    assert_difference -> { broadcasts("document_action_#{@document_action.id}").size }, 1 do
      assert_difference -> { broadcasts("student_submission_#{@document_action.student_submission_id}").size }, 1 do
        DocumentAction::Broadcaster.new(@document_action).broadcast_update
      end
    end
  end
end
