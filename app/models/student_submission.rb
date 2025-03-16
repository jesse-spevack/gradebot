# frozen_string_literal: true

# The StudentSubmission model represents a student's document that is being processed by the system
# for grading. It tracks the document through various states from submission to completion.
#
# == Status Flow
# A submission follows this standard flow:
#   pending -> processing -> completed
#
# If processing fails, it can go to the failed state:
#   pending -> processing -> failed
#   pending -> failed (for direct failures)
#
# Once a submission is in completed or failed state, it cannot transition to other states.
# Exception: Failed submissions can be retried using the retry! method which resets them to pending.
#
# == Attributes
#   * grading_task - The grading task this submission belongs to
#   * original_doc_id - Google Doc ID of the original submission document
#   * status - Current status of the submission (pending, processing, completed, failed)
#   * feedback - Textual feedback for the student
#   * graded_doc_id - Google Doc ID of the graded document (when completed)
class StudentSubmission < ApplicationRecord
  # Use optimistic locking
  # This model has a lock_version column for this purpose

  # Constants - kept for reference but actual transition logic moved to StatusManager
  ALLOWED_TRANSITIONS = {
    pending: [ :processing, :failed ],
    processing: [ :completed, :failed ],
    completed: [],
    failed: []
  }.freeze

  # Associations
  belongs_to :grading_task

  # Validations
  validates :original_doc_id, presence: true

  # Status transitions are now validated by StatusManager service
  # Status updates should go through StatusManager.transition_submission

  # Callbacks
  after_create_commit :broadcast_creation

  # Enums
  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :processing, -> { where(status: :processing) }
  scope :completed, -> { where(status: :completed) }
  scope :failed, -> { where(status: :failed) }
  scope :in_progress, -> { where(status: [ :pending, :processing ]) }
  scope :by_grading_task, ->(task_id) { where(grading_task_id: task_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :needs_processing, -> { pending.oldest_first }
  scope :created_after, ->(date) { where("created_at >= ?", date) }
  scope :created_before, ->(date) { where("created_at <= ?", date) }

  # Methods for accessing structured grading data

  # Returns the document title if available
  # @return [String] Document title or a default value
  def document_title
    return metadata["doc_title"] if metadata.present? && metadata["doc_title"].present?
    "Document #{original_doc_id.truncate(10)}"
  end

  # Returns an array of strengths from the structured data
  # @return [Array<String>] Array of strengths
  def display_strengths
    return [] if strengths.blank?

    # Split by newline if stored as a string with newlines
    if strengths.is_a?(String) && strengths.include?("\n")
      strengths.split("\n- ").map { |s| s.gsub(/^- /, "") }
    # Convert from array if stored as JSON/array
    elsif strengths.is_a?(String) && (strengths.start_with?("[") || strengths.start_with?("{"))
      begin
        JSON.parse(strengths)
      rescue JSON::ParserError
        [ strengths ]
      end
    # Handle simple string case
    elsif strengths.is_a?(String)
      [ strengths ]
    # Handle array case
    elsif strengths.is_a?(Array)
      strengths
    else
      []
    end
  end

  # Returns an array of opportunities from the structured data
  # @return [Array<String>] Array of opportunities
  def display_opportunities
    return [] if opportunities.blank?

    # Split by newline if stored as a string with newlines
    if opportunities.is_a?(String) && opportunities.include?("\n")
      opportunities.split("\n- ").map { |o| o.gsub(/^- /, "") }
    # Convert from array if stored as JSON/array
    elsif opportunities.is_a?(String) && (opportunities.start_with?("[") || opportunities.start_with?("{"))
      begin
        JSON.parse(opportunities)
      rescue JSON::ParserError
        [ opportunities ]
      end
    # Handle simple string case
    elsif opportunities.is_a?(String)
      [ opportunities ]
    # Handle array case
    elsif opportunities.is_a?(Array)
      opportunities
    else
      []
    end
  end

  # Returns the rubric scores as a hash
  # @return [Hash] Hash of rubric criterion and scores
  def display_rubric_scores
    return {} if rubric_scores.blank?

    # Convert from string if stored as JSON string
    if rubric_scores.is_a?(String)
      begin
        JSON.parse(rubric_scores)
      rescue JSON::ParserError
        {}
      end
    # Handle hash case
    elsif rubric_scores.is_a?(Hash)
      rubric_scores
    else
      {}
    end
  end

  # Returns true if this submission can transition to the given status
  # Delegated to StatusManager
  #
  # @param new_status [Symbol, String] The status to check transition to
  # @return [Boolean] True if transition is allowed, false otherwise
  def can_transition_to?(new_status)
    StatusManager.can_transition_submission?(self, new_status)
  end

  # Retry a failed submission by resetting it to pending
  # Delegated to StatusManager
  #
  # @return [Boolean] True if the retry succeeded, false otherwise
  def retry!
    StatusManager.retry_submission(self)
  end

  # Returns true if the submission has feedback
  # @return [Boolean] True if the submission has feedback, false otherwise
  def show_feedback?
    feedback.present?
  end

  # Returns true if the submission has strengths
  # @return [Boolean] True if the submission has strengths, false otherwise
  def show_strengths?
    strengths.present?
  end

  # Returns true if the submission has opportunities
  # @return [Boolean] True if the submission has opportunities, false otherwise
  def show_opportunities?
    opportunities.present?
  end

  # Returns true if the submission has rubric scores
  # @return [Boolean] True if the submission has rubric scores, false otherwise
  def show_rubric_scores?
    rubric_scores.present?
  end

  # Returns true if the submission has a teacher's summary
  # @return [Boolean] True if the submission has a teacher's summary, false otherwise
  def show_teacher_summary?
    metadata.present? && metadata["summary"].present?
  end

  # Returns true if the submission has a teacher's question
  # @return [Boolean] True if the submission has a teacher's question, false otherwise
  def show_teacher_question?
    metadata.present? && metadata["question"].present?
  end

  # Returns the teacher's question
  # @return [String] The teacher's question
  def question
    metadata["question"] || ""
  end

  # Returns the teacher's summary
  # @return [String] The teacher's summary
  def summary
    metadata["summary"] || ""
  end

  private

  # Broadcasts the creation of this submission to the appropriate Turbo Stream
  # @return [void]
  def broadcast_creation
    # Use a transaction to ensure atomicity
    ActiveRecord::Base.transaction do
      begin
        # Reload to ensure we have the latest data
        reload

        # If this is the first submission, replace the empty state
        # Use count directly from the database to avoid race conditions
        if grading_task.student_submissions.count == 1
          Turbo::StreamsChannel.broadcast_replace_to(
            "grading_task_#{grading_task_id}",
            target: "student_submissions",
            partial: "student_submissions/submission_list",
            locals: { submissions: grading_task.student_submissions.oldest_first, grading_task: grading_task }
          )
        else
          # For subsequent submissions, always update the entire list
          # This ensures all submissions are visible without a page refresh
          Turbo::StreamsChannel.broadcast_replace_to(
            "grading_task_#{grading_task_id}_submissions",
            target: "student_submissions_list_#{grading_task_id}",
            partial: "student_submissions/submission_list",
            locals: {
              submissions: grading_task.student_submissions.reload.oldest_first,
              grading_task: grading_task
            }
          )
        end

        # Also broadcast to the submissions list container to ensure it's updated
        Turbo::StreamsChannel.broadcast_replace_to(
          "grading_task_#{grading_task_id}",
          target: "submissions_list_container_#{grading_task_id}",
          partial: "student_submissions/submissions_list_container",
          locals: {
            grading_task: grading_task.reload,
            submissions: grading_task.student_submissions.reload.oldest_first
          }
        )

        # Also update the grading task's progress section
        Turbo::StreamsChannel.broadcast_update_to(
          "grading_task_#{grading_task_id}",
          target: "progress_section_#{ActionView::RecordIdentifier.dom_id(grading_task)}",
          partial: "grading_tasks/progress_section",
          locals: {
            grading_task: grading_task.reload,
            student_submissions: grading_task.student_submissions.reload.oldest_first
          }
        )

        # Also broadcast to the entire grading task to ensure all components are updated
        Turbo::StreamsChannel.broadcast_replace_to(
          "grading_task_#{grading_task_id}",
          target: ActionView::RecordIdentifier.dom_id(grading_task),
          partial: "grading_tasks/grading_task",
          locals: {
            grading_task: grading_task.reload,
            student_submissions: grading_task.student_submissions.reload.oldest_first
          }
        )
      rescue => e
        # Log any errors but don't crash
        Rails.logger.error("Error broadcasting submission creation: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end
    end
  end
end
