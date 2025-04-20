# frozen_string_literal: true

# Represents a request to kick off a new grading task
#
# This class encapsulates all parameters needed to create a grading task
# and provides validation to ensure required fields are present and
# properly formatted. It serves as a bridge between the controller's parameters
# and the service layer.
class GradingTaskKickOffRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  # The user creating the grading task
  attr_accessor :user

  # The feedback tone for this grading task (encouraging, neutral, critical)
  attr_accessor :feedback_tone

  # The raw rubric text provided by the user
  attr_accessor :rubric_raw_text

  # Whether to generate the rubric with AI
  attr_accessor :ai_generate_rubric

  # Assignment prompt attributes
  attr_accessor :assignment_prompt_title, :assignment_prompt_subject,
                :assignment_prompt_grade_level, :assignment_prompt_word_count,
                :assignment_prompt_content, :assignment_prompt_due_date

  # Document data for student submissions
  attr_reader :document_data

  # Sets document_data with a DocumentDataCollection
  # @param data [Array, DocumentDataCollection] Document data
  def document_data=(data)
    @document_data = data.is_a?(DocumentDataCollection) ? data : DocumentDataCollection.new(data)
  end

  # Validations
  validates :user, presence: true
  validates :assignment_prompt_title, presence: true
  validates :assignment_prompt_content, presence: true
  validates :feedback_tone, inclusion: { in: GradingTask::FEEDBACK_TONE.keys.map(&:to_s) }, allow_nil: true
  validate :validate_document_data
  validate :validate_rubric_presence

  # Creates a GradingTaskKickOffRequest from controller parameters
  #
  # @param params [ActionController::Parameters] The permitted params from the controller
  # @param user [User] The current user
  # @param document_data [Array] The JSON-parsed document data
  # @return [GradingTaskKickOffRequest] A new instance
  def self.from_controller_params(params, user, document_data)
    assignment_prompt = params[:assignment_prompt_attributes] || {}

    new(
      user: user,
      feedback_tone: params[:feedback_tone],
      rubric_raw_text: params[:rubric_raw_text],
      ai_generate_rubric: params[:ai_generate_rubric] == "1",
      assignment_prompt_title: assignment_prompt[:title],
      assignment_prompt_subject: assignment_prompt[:subject],
      assignment_prompt_grade_level: assignment_prompt[:grade_level],
      assignment_prompt_word_count: assignment_prompt[:word_count],
      assignment_prompt_content: assignment_prompt[:content],
      assignment_prompt_due_date: assignment_prompt[:due_date],
      document_data: document_data
    )
  end

  private

  def validate_document_data
    return if document_data.nil?

    unless document_data.valid?
      document_data.errors.full_messages.each do |message|
        errors.add(:document_data, message)
      end
    end
  end

  def validate_rubric_presence
    # Skip validation if AI generation is enabled
    return if ai_generate_rubric

    # Otherwise, require rubric text
    errors.add(:rubric_raw_text, "can't be blank") if rubric_raw_text.blank?
  end
end
