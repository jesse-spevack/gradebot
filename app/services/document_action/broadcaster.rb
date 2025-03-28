# frozen_string_literal: true

class DocumentAction::Broadcaster
  attr_reader :document_action

  def initialize(document_action)
    @document_action = document_action
  end

  def broadcast_update
    broadcast_replace_to(
      "document_action_#{@document_action.id}",
      "document_action_status_#{@document_action.id}",
      "document_actions/status"
    )

    broadcast_replace_to(
      "student_submission_#{@document_action.student_submission_id}",
      "document_action_section_#{document_action.student_submission_id}",
      "document_actions/section"
    )
  end

  private

  def broadcast_replace_to(channel, target, partial)
    Turbo::StreamsChannel.broadcast_replace_to(
      channel,
      target: target,
      partial: partial,
      locals: { document_action: document_action }
    )
  end
end
