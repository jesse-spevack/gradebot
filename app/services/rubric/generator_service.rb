# frozen_string_literal: true

# This service is responsible for generating a rubric for a given assignment prompt and grading task.
# It uses an LLM to generate a rubric, and then parses the response to create a new rubric.
class Rubric::GeneratorService
  def self.generate(assignment_prompt:, grading_task:, rubric:)
    new(
      assignment_prompt: assignment_prompt,
      grading_task: grading_task,
      rubric: rubric,
    ).generate
  end

  attr_reader :assignment_prompt, :grading_task, :rubric, :config

  def initialize(assignment_prompt:, grading_task:, rubric:)
    @assignment_prompt = assignment_prompt
    @grading_task = grading_task
    @rubric = rubric
    @config = LLM::Configuration.model_for(:generate_rubric)
  end

  def generate
    prompt = build_prompt
    Rails.logger.info("LLM prompt: #{prompt}")

    llm_request = LLMRequest.new(
      prompt: prompt,
      llm_model_name: config[:model],
      request_type: "generate_rubric",
      trackable: grading_task,
      user: grading_task.user,
      metadata: {
        prompt_length: prompt.length
      },
      temperature: config[:temperature],
      max_tokens: config[:max_tokens]
    )

    Rails.logger.info("Making LLM request with model: #{llm_request.llm_model_name}")
    response = LLM::Client.new.generate(llm_request)

    Rails.logger.info("LLM response: #{response}")
    Rails.logger.info("LLM response content: #{response[:content]}")

    begin
      Rubric::CriteriaLevelCreationService.parse(
        response: response[:content],
        rubric: rubric
      )
    rescue => e
      Rails.logger.error("Error parsing LLM response: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      retry_request(llm_request)
    end

    rubric.reload
  end

  private

  def build_prompt
    if rubric.raw_rubric.present?
      PromptBuilder.build(:user_supplied_raw_rubric, { assignment_prompt: assignment_prompt, raw_rubric: rubric.raw_rubric })
    else
      PromptBuilder.build(:ai_generated_rubric, { assignment_prompt: assignment_prompt })
    end
  end

  def retry_request(llm_request)
    Rails.logger.info("Retrying LLM request")
    response = LLM::Client.new.generate(llm_request)
    begin
      Rubric::CriteriaLevelCreationService.parse(
        response: response[:content],
        rubric: rubric
      )
    rescue => e
      Rails.logger.error("Error parsing LLM response on second attempt: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise e
    end
  end
end
