class GradingRubricFormatterService
  def initialize
    @config = LLM::Configuration.model_for(:format_rubric)
  end


  def format(grading_task)
    grading_rubric = grading_task.grading_rubric

    RetryHandler.with_retry do
      prompt = PromptBuilder.build(:format_grading_rubric, {
        grading_rubric: grading_rubric
      })

      Rails.logger.info("LLM prompt: #{prompt}")

      metadata = {
        prompt_length: prompt.length,
        grading_rubric_length: grading_rubric.length
      }

      llm_request = LLMRequest.new(
        prompt: prompt,
        llm_model_name: @config[:model],
        request_type: "format_rubric",
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
        formatted_grading_rubric: response[:content]
      )

      grading_task
    end
  rescue StandardError => e
    Rails.logger.error("Error during grading rubric formatting: #{e.message}")
    Rails.logger.error("Error backtrace: #{e.backtrace&.first(10)&.join("\n")}")
  end
end
