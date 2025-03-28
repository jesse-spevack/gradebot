# frozen_string_literal: true

class PostFeedbackJob < ApplicationJob
  queue_as :default

  def perform(document_action_id)
    document_action = DocumentAction.find_by(id: document_action_id)
    return unless document_action

    document_action.start_processing!

    begin
      DocumentAction::PostFeedbackService.post(document_action)

      document_action.complete!
    rescue => e
      Rails.logger.error("Error processing document action #{document_action_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      document_action.fail!(e.message)
    end
  end
end
