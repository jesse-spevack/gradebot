require "test_helper"
require "minitest/mock"

class PostFeedbackJobTest < ActiveJob::TestCase
  # Setup
  setup do
    @document_action_attributes = {
      student_submission: student_submissions(:completed_submission),
      action_type: :post_feedback,
      status: :pending
    }
  end

  test "enqueues job when document action is created" do
    assert_enqueued_with(job: PostFeedbackJob) do
      DocumentAction.create!(@document_action_attributes)
    end
  end

  test "job calls DocumentAction::PostFeedbackService with document action" do
    document_action = DocumentAction.create!(@document_action_attributes)
    DocumentAction::PostFeedbackService.expects(:post).with(document_action).once
    PostFeedbackJob.perform_now(document_action.id)
  end

  test "job handles errors gracefully" do
    document_action = DocumentAction.create!(@document_action_attributes)
    document_action.processing!

    error_message = "API connection error"
    DocumentAction::PostFeedbackService.expects(:post).with(document_action).raises(StandardError.new(error_message))

    PostFeedbackJob.perform_now(document_action.id)

    document_action.reload
    assert_equal "failed", document_action.status
    assert_includes document_action.error_message.to_s, error_message
  end

  test "job does nothing when document action is not found" do
    non_existent_id = 9999

    assert_nothing_raised do
      PostFeedbackJob.perform_now(non_existent_id)
    end
  end
end
