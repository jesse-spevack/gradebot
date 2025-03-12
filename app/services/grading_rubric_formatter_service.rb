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

      # Reload the grading task to get the latest lock_version before updating
      grading_task.reload

      # Try to update with retry logic specifically for optimistic locking errors
      update_with_retry(grading_task, response[:content])

      grading_task
    end
  rescue StandardError => e
    Rails.logger.error("Error during grading rubric formatting: #{e.message}")
    Rails.logger.error("Error backtrace: #{e.backtrace&.first(10)&.join("\n")}")
  end

  private

  # Update the grading task with retry logic for optimistic locking errors
  # @param grading_task [GradingTask] The grading task to update
  # @param formatted_content [String] The formatted content to save
  # @param max_retries [Integer] Maximum number of retries
  # @return [Boolean] Whether the update was successful
  def update_with_retry(grading_task, formatted_content, max_retries = 3)
    retries = 0
    begin
      grading_task.update(formatted_grading_rubric: formatted_content)
    rescue ActiveRecord::StaleObjectError => e
      retries += 1
      if retries <= max_retries
        Rails.logger.info("Retrying update after optimistic locking error (attempt #{retries}/#{max_retries})")
        grading_task.reload
        retry
      else
        Rails.logger.error("Failed to update grading task after #{max_retries} attempts: #{e.message}")
        raise e
      end
    end
  end
end
