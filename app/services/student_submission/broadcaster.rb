# frozen_string_literal: true

# The StudentSubmission::Broadcaster service is responsible for broadcasting updates about student submissions
# to various UI components using Turbo Streams. It encapsulates all broadcasting logic in one place
# and organizes broadcasts by UI component.
#
# This service handles two main types of broadcasts:
# 1. Creation broadcasts - when a new submission is created
# 2. Update broadcasts - when an existing submission is updated
#
# It also handles special cases like the first submission for a grading task.
class StudentSubmission::Broadcaster
  # Initialize with a student submission
  # @param submission [StudentSubmission] The submission to broadcast
  def initialize(student_submission)
    @student_submission = student_submission
    load_data
  end

  # Broadcast an update to an existing submission
  # @return [void]
  def broadcast_update
    # Use a transaction to ensure atomicity
    ActiveRecord::Base.transaction do
      begin
        # Broadcast to the submission card and table row
        broadcast_submission_card
        broadcast_submission_table_row

        # Broadcast to the submission detail page
        broadcast_submission_detail
        broadcast_submission_header_status

        # Also update the grading task components
        broadcast_task_components
      rescue => e
        # Log any errors but don't crash
        Rails.logger.error("Error broadcasting submission update: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end
    end
  end

  private

  # Load all necessary data once to avoid multiple database queries
  # @return [void]
  def load_data
    # Only reload if the submission has been persisted
    @student_submission.reload if @student_submission.persisted?

    @grading_task = @student_submission.grading_task
    # Only reload the grading task if it has been persisted
    @grading_task.reload if @grading_task.persisted?

    @student_submissions = @grading_task.student_submissions.oldest_first
  end

  # Check if this is the first submission for the grading task
  # @return [Boolean] True if this is the first submission
  def first_submission?
    @grading_task.student_submissions.count == 1
  end

  # Broadcast updates for the first submission
  # This replaces the empty state with the submission list
  # @return [void]
  def broadcast_first_submission
    # For the first submission, we need to replace the empty state
    # and update several components

    # 1. Replace the empty state with the submission list
    broadcast_replace_to(
      grading_task_channel,
      "student_submissions",
      "student_submissions/submission_list",
      submission_list_locals
    )

    # 2. Update the submissions container
    broadcast_submissions_container

    # 3. Update the progress section
    broadcast_progress_section

    # 4. Update the entire grading task
    broadcast_grading_task
  end

  # Broadcast updates for a subsequent submission
  # This updates the submission list and related components
  # @return [void]
  def broadcast_subsequent_submission
    # For subsequent submissions, we update the submission list
    # in a different channel
    broadcast_replace_to(
      "#{grading_task_channel}_submissions",
      submissions_list_id,
      "student_submissions/submission_list",
      submission_list_locals
    )

    # Also update the submissions container and progress section
    broadcast_submissions_container
    broadcast_progress_section
    broadcast_grading_task
  end

  # Broadcast the submission list component
  # @return [void]
  def broadcast_submission_list
    broadcast_replace_to(
      grading_task_channel,
      "student_submissions",
      "student_submissions/submission_list",
      submission_list_locals
    )
  end

  # Broadcast the submissions container component
  # @return [void]
  def broadcast_submissions_container
    broadcast_replace_to(
      grading_task_channel,
      submissions_container_id,
      "student_submissions/submissions_list_container",
      submission_list_locals
    )
  end

  # Broadcast the progress section component
  # @return [void]
  def broadcast_progress_section
    broadcast_update_to(
      grading_task_channel,
      progress_section_id,
      "grading_tasks/progress_section",
      progress_section_locals
    )
  end

  # Broadcast the entire grading task
  # @return [void]
  def broadcast_grading_task
    broadcast_replace_to(
      grading_task_channel,
      dom_id(@grading_task),
      "grading_tasks/grading_task",
      grading_task_locals
    )
  end

  # Broadcast the submission card (mobile view)
  # @return [void]
  def broadcast_submission_card
    broadcast_replace_to(
      grading_task_channel,
      dom_id(@student_submission),
      "student_submissions/submission_card",
      { student_submission: @student_submission }
    )
  end

  # Broadcast the submission table row (desktop view)
  # @return [void]
  def broadcast_submission_table_row
    broadcast_replace_to(
      grading_task_channel,
      "#{dom_id(@student_submission)}_table_row",
      "student_submissions/table_row",
      { student_submission: @student_submission }
    )
  end

  # Broadcast the submission detail view
  # @return [void]
  def broadcast_submission_detail
    broadcast_replace_to(
      submission_channel,
      "#{dom_id(@student_submission)}_detail",
      "student_submissions/detail",
      { student_submission: @student_submission }
    )
  end

  # Broadcast the submission header status
  # @return [void]
  def broadcast_submission_header_status
    broadcast_replace_to(
      submission_channel,
      "header_status",
      "student_submissions/header_status",
      { student_submission: @student_submission }
    )
  end

  # Broadcast updates to individual components of a grading task
  # @return [void]
  def broadcast_task_components
    # 1. Update the status badge
    broadcast_replace_to(
      grading_task_channel,
      "#{dom_id(@grading_task)}_status_badge",
      "grading_tasks/task_status_badge",
      { grading_task: @grading_task }
    )

    # 2. Update the progress metrics
    broadcast_replace_to(
      grading_task_channel,
      "#{dom_id(@grading_task)}_progress_metrics",
      "grading_tasks/progress_metrics",
      progress_section_locals
    )

    # 3. Update the submission counts
    broadcast_replace_to(
      grading_task_channel,
      "#{dom_id(@grading_task)}_submission_counts",
      "grading_tasks/submission_counts",
      { student_submissions: @student_submissions }
    )

    # 4. Send a full update for the progress section
    broadcast_progress_section
  end

  # Helper method to broadcast a replace action
  # @param channel [String] The channel to broadcast to
  # @param target [String] The target DOM ID
  # @param partial [String] The partial to render
  # @param locals [Hash] The locals to pass to the partial
  # @return [void]
  def broadcast_replace_to(channel, target, partial, locals)
    Turbo::StreamsChannel.broadcast_replace_to(
      channel,
      target: target,
      partial: partial,
      locals: locals
    )
  end

  # Helper method to broadcast an update action
  # @param channel [String] The channel to broadcast to
  # @param target [String] The target DOM ID
  # @param partial [String] The partial to render
  # @param locals [Hash] The locals to pass to the partial
  # @return [void]
  def broadcast_update_to(channel, target, partial, locals)
    Turbo::StreamsChannel.broadcast_update_to(
      channel,
      target: target,
      partial: partial,
      locals: locals
    )
  end

  # Generate a DOM ID for a record
  # @param record [ActiveRecord::Base] the record to generate an ID for
  # @return [String] the DOM ID
  def dom_id(record)
    ActionView::RecordIdentifier.dom_id(record)
  end

  # Channel for grading task broadcasts
  # @return [String] The channel name
  def grading_task_channel
    "grading_task_#{@grading_task.id}"
  end

  # Channel for submission broadcasts
  # @return [String] The channel name
  def submission_channel
    "student_submission_#{@student_submission.id}"
  end

  # ID for the submissions list container
  # @return [String] The DOM ID
  def submissions_container_id
    "submissions_list_container_#{@grading_task.id}"
  end

  # ID for the submissions list
  # @return [String] The DOM ID
  def submissions_list_id
    "student_submissions_list_#{@grading_task.id}"
  end

  # ID for the progress section
  # @return [String] The DOM ID
  def progress_section_id
    "progress_section_#{dom_id(@grading_task)}"
  end

  # Locals for submission list partials
  # @return [Hash] The locals
  def submission_list_locals
    {
      student_submissions: @student_submissions,
      grading_task: @grading_task
    }
  end

  # Locals for progress section partials
  # @return [Hash] The locals
  def progress_section_locals
    {
      grading_task: @grading_task,
      student_submissions: @student_submissions
    }
  end

  # Locals for grading task partials
  # @return [Hash] The locals
  def grading_task_locals
    {
      grading_task: @grading_task,
      student_submissions: @student_submissions
    }
  end
end
