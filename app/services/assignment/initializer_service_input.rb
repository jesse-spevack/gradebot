# frozen_string_literal: true

# Input parameters for the Assignment::InitializerService
class Assignment::InitializerServiceInput
  attr_reader :current_user

  def initialize(current_user:, assignment_params:, document_data:)
    @current_user = current_user
    @assignment_params = assignment_params
    @document_data = document_data
  end

  def title
    @assignment_params[:title]
  end

  def subject
    @assignment_params[:subject]
  end

  def grade_level
    @assignment_params[:grade_level]
  end

  def description
    @assignment_params[:description]
  end

  def instructions
    @assignment_params[:instructions]
  end

  def feedback_tone
    @assignment_params[:feedback_tone]
  end

  def raw_rubric_text
    @assignment_params[:raw_rubric_text]
  end

  def document_data
    @document_data.map { |datum| datum.symbolize_keys }
  end

  def to_assignment_params
    {
      title: title,
      subject: subject,
      grade_level: grade_level,
      description: description,
      instructions: instructions,
      feedback_tone: feedback_tone,
      raw_rubric_text: raw_rubric_text
    }
  end
end
