class GradingTask::Broadcaster
  attr_reader :grading_task

  def initialize(grading_task)
    @grading_task = grading_task.reload
  end

  def broadcast_grading_task_assignment_prompt_update
    broadcast_replace_to(
      target: "assignment_prompt_container_#{grading_task.id}",
      partial: "grading_tasks/assignment_prompt_container",
    )
  end

  def broadcast_grading_task_grading_rubric_update
    broadcast_replace_to(
      target: "grading_rubric_container_#{grading_task.id}",
      partial: "grading_tasks/grading_rubric_container",
    )
  end

  def broadcast_grading_task_status_update
    broadcast_replace_to(
      target: "#{dom_id}_status_badge",
      partial: "grading_tasks/task_status_badge",
    )
  end

  private

  def broadcast_replace_to(target:, partial:)
    Turbo::StreamsChannel.broadcast_replace_to(
      "grading_task_#{grading_task.id}",
      target: target,
      partial: partial,
      locals: { grading_task: grading_task }
    )
  end

  def dom_id
    ActionView::RecordIdentifier.dom_id(grading_task)
  end
end
