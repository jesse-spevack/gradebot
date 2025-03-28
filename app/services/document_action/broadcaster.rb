# frozen_string_literal: true

class DocumentAction::Broadcaster
  attr_reader :document_action

  def initialize(document_action)
    @document_action = document_action
  end

  def broadcast_update
    broadcast_replace_to(
      "document_action_#{@document_action.id}",
      "document_action_status_#{@document_action.id}"
    )

    broadcast_replace_to(
      "student_submission_#{@document_action.student_submission_id}",
      "document_action_section_#{document_action.student_submission_id}"
    )
  end

  private

  def broadcast_replace_to(channel, target)
    Turbo::StreamsChannel.broadcast_replace_to(
      channel,
      target: target,
      partial: "document_actions/status",
      locals: { document_action: document_action }
    )
  end
end
