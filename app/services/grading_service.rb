# frozen_string_literal: true

# Service for grading student submissions using LLM
#
# This service handles the interaction with LLM models to generate
# feedback and grades for student submissions based on assignment prompts
# and grading rubrics.
class GradingService
  attr_reader :config

  # Initialize a new grading service
  #
  # @param config [Hash, nil] Optional configuration hash, defaults to LLM::Configuration.model_for(:grade_assignment)
  def initialize(config = nil)
    @config = config || LLM::Configuration.model_for(:grade_assignment)
  end

  # Grade a student submission using LLM
  #
  # @param document_content [String] The content of the student's document
  # @param assignment_prompt [String] The original assignment prompt
  # @param grading_rubric [String] The grading rubric to use
  # @return [GradingResponse] A response object containing feedback, grade, and rubric scores
  def grade_submission(document_content, assignment_prompt, grading_rubric)
    return GradingResponse.error("LLM grading is not enabled. Please contact an administrator.") unless LLM::Configuration.enabled?

    RetryHandler.with_retry do
      content = ContentCleaner.clean(document_content)
      prompt = PromptBuilder.build(:grading, {
        document_content: content,
        assignment_prompt: assignment_prompt,
        grading_rubric: grading_rubric
      })

      response = LLMClient.new(@config).generate(prompt)
      result = ResponseParser.parse(response[:content])

      GradingResponse.new(
        feedback: result.feedback,
        strengths: result.strengths,
        opportunities: result.opportunities,
        overall_grade: result.overall_grade,
        rubric_scores: result.rubric_scores
      )
    end
  rescue ParsingError => e
    Rails.logger.error("Failed to parse LLM response: #{e.message}")
    Rails.logger.error("Error backtrace: #{e.backtrace&.first(10)&.join("\n")}")
    GradingResponse.error("Failed to parse LLM response: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("Error during grading: #{e.message}")
    Rails.logger.error("Error backtrace: #{e.backtrace&.first(10)&.join("\n")}")
    GradingResponse.error("Error during grading: #{e.message}")
  end
end
