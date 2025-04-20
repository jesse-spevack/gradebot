# frozen_string_literal: true

# This service is used to kick off a grading task.
# It creates a rubric, a grading task, and an assignment prompt.
# It also creates a raw rubric if the raw text is present.
# It returns the created grading task.
class GradingTask::KickOffService
  class InvalidRequestError < StandardError; end

  def self.call(request)
    new(request).call
  end

  def initialize(request)
    raise InvalidRequestError, "Request must be a GradingTaskKickOffRequest" unless request.is_a?(GradingTaskKickOffRequest)
    raise InvalidRequestError, "Invalid request: #{request.errors.full_messages.join(', ')}" unless request.valid?

    @request = request
  end

  def call
    ActiveRecord::Base.transaction do
      # 1. Create the Rubric
      Rails.logger.info("Creating rubric...")
      rubric = create_rubric
      Rails.logger.info("Rubric created: #{rubric.id}")

      # 2. Create the GradingTask with reference to the Rubric
      Rails.logger.info("Creating grading task...")
      @grading_task = create_grading_task(rubric)
      Rails.logger.info("Grading task created: #{@grading_task.id}")

      # 3. Create the AssignmentPrompt with reference to the GradingTask
      Rails.logger.info("Creating assignment prompt...")
      assignment_prompt = create_assignment_prompt(@grading_task)
      Rails.logger.info("Assignment prompt created: #{assignment_prompt.id}")
      log_info = {
        grading_task_id: @grading_task.id,
        rubric_id: rubric.id,
        assignment_prompt_id: assignment_prompt.id
      }

      # 4. Create the RawRubric with reference to the Rubric
      if @request.rubric_raw_text.present?
        Rails.logger.info("Creating raw rubric...")
        raw_rubric = create_raw_rubric(rubric)
        log_info[:raw_rubric_id] = raw_rubric.id
        Rails.logger.info("Raw rubric created: #{raw_rubric.id}")
      end

      # Return the GradingTask
      Rails.logger.info("GradingTask::Kickoff service completed successfully: #{log_info}")
      @grading_task
    end
  end

  private

  def create_rubric
    Rubric::CreationService.call(
      user: @request.user,
      title: @request.assignment_prompt_title
    )
  end

  def create_grading_task(rubric)
    GradingTask::CreationService.call(
      user: @request.user,
      rubric: rubric,
      feedback_tone: @request.feedback_tone
    )
  end

  def create_assignment_prompt(grading_task)
    AssignmentPrompt::CreationService.call(
      grading_task: grading_task,
      title: @request.assignment_prompt_title,
      subject: @request.assignment_prompt_subject,
      grade_level: @request.assignment_prompt_grade_level,
      word_count: @request.assignment_prompt_word_count,
      content: @request.assignment_prompt_content,
      due_date: @request.assignment_prompt_due_date
    )
  end

  def create_raw_rubric(rubric)
    Rubric::RawRubricCreationService.call(
      rubric: rubric,
      raw_text: @request.rubric_raw_text,
      grading_task: @grading_task
    )
  end
end
