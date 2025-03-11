class AssignmentPromptFormatterService
  def initialize
    @config = LLM::Configuration.model_for(:format_assignment)
  end


  def format(grading_task)
    assignment_prompt = grading_task.assignment_prompt

    RetryHandler.with_retry do
      prompt = PromptBuilder.build(:format_assignment, {
        assignment_prompt: assignment_prompt
      })

      Rails.logger.info("LLM prompt: #{prompt}")

      metadata = {
        prompt_length: prompt.length,
        assignment_length: assignment_prompt.length
      }

      llm_request = LLMRequest.new(
        prompt: prompt,
        llm_model_name: @config[:model],
        request_type: "format_assignment",
        trackable: grading_task,
        user: grading_task.user,
        metadata: metadata,
        temperature: @config[:temperature],
        max_tokens: @config[:max_tokens]
      )

      Rails.logger.info("Making LLM request with model: #{llm_request.llm_model_name}")

      response = LLM::Client.new.generate(llm_request)

      Rails.logger.info("LLM response: #{response}")
      Rails.logger.info("LLM response content: #{response[:content]}")

      grading_task.update(
        formatted_assignment_prompt: response[:content]
      )

      grading_task
    end
  rescue StandardError => e
    Rails.logger.error("Error during assignment prompt formatting: #{e.message}")
    Rails.logger.error("Error backtrace: #{e.backtrace&.first(10)&.join("\n")}")
  end
end
