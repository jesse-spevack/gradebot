# frozen_string_literal: true

class StudentSubmission < ApplicationRecord
  has_prefix_id :ss
  # Use optimistic locking
  # This model has a lock_version column for this purpose

  ALLOWED_TRANSITIONS = {
    pending: [ :processing, :failed ],
    processing: [ :completed, :failed ],
    completed: [],
    failed: []
  }.freeze

  belongs_to :grading_task
  belongs_to :document_selection, optional: true
  has_many :document_actions

  validates :original_doc_id, presence: true

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

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

  def last_post_feedback_action
    document_actions.post_feedback.most_recent.first
  end

  def feedback_posted?
    document_actions.completed_post_feedback.exists?
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
end
