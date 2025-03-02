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
  # @return [Hash] A hash containing feedback, grade, and rubric scores
  def grade_submission(document_content, assignment_prompt, grading_rubric)
    # Check if LLM features are enabled
    unless LLM::Configuration.enabled?
      return {
        error: "LLM grading is not enabled. Please contact an administrator.",
        feedback: "LLM grading is not enabled. Please contact an administrator.",
        grade: "Ungraded",
        rubric_scores: {}
      }
    end

    begin
      # Create the LLM client
      client = LLM::ClientFactory.create(@config[:model])

      # Construct the prompt
      prompt = build_grading_prompt(document_content, assignment_prompt, grading_rubric)

      # Send the prompt to the LLM
      response = client.generate(prompt: prompt)

      # Process the response
      feedback = response[:content]
      grade = extract_grade(feedback)
      rubric_scores = extract_rubric_scores(feedback, grading_rubric)

      # Return the processed response
      {
        feedback: feedback,
        grade: grade,
        rubric_scores: rubric_scores,
        metadata: response[:metadata]
      }
    rescue => e
      # Log the error
      Rails.logger.error("Error during grading: #{e.message}")

      # Return error information
      {
        error: "LLM grading failed: #{e.message}",
        feedback: "Error during grading. Please try again later or contact support.",
        grade: "Ungraded",
        rubric_scores: {}
      }
    end
  end

  private

  # Build a prompt for the LLM to grade the submission
  #
  # @param document_content [String] The content of the student's document
  # @param assignment_prompt [String] The original assignment prompt
  # @param grading_rubric [String] The grading rubric to use
  # @return [String] The constructed prompt
  def build_grading_prompt(document_content, assignment_prompt, grading_rubric)
    <<~PROMPT
      You are an educational grading assistant. Your task is to grade a student submission based on the assignment prompt and grading rubric provided below.

      ASSIGNMENT PROMPT:
      #{assignment_prompt}

      GRADING RUBRIC:
      #{grading_rubric}

      STUDENT SUBMISSION:
      #{document_content}

      Please grade this submission according to the rubric. Provide:
      1. A detailed feedback section with constructive comments
      2. Specific strengths and weaknesses of the submission
      3. A score for each rubric criterion in the format "Category: X/Y" (e.g., "Content: 35/40")
      4. An overall grade (A, B+, C, etc.)

      Format your response as a JSON object with the following keys:
      - feedback: A detailed feedback section with constructive comments
      - scores: A hash of scores for each rubric criterion
      - overall_grade: An overall grade (A, B+, C, etc.)
    PROMPT
  end

  # Extract the overall grade from the LLM response
  #
  # @param content [String] The LLM response content
  # @return [String] The extracted grade or "Ungraded" if none found
  def extract_grade(content)
    # Try to match different grade formats
    # Format 1: "Overall Grade: A" or "Grade: B+"
    match = content.match(/(?:overall\s+)?grade:?\s*([A-F][+-]?)/i)
    return match[1] if match

    # Format 2: "The grade is B+" or similar phrases
    match = content.match(/(?:the\s+)?grade\s+is:?\s*([A-F][+-]?)/i)
    return match[1] if match

    # No match found
    "Ungraded"
  end

  # Extract rubric scores from the LLM response
  #
  # @param content [String] The LLM response content
  # @param rubric [String] The original rubric (used to identify criteria)
  # @return [Hash<Symbol, Integer>] Hash of criteria and scores
  def extract_rubric_scores(content, rubric)
    # Extract the rubric criteria from the original rubric
    criteria = extract_criteria_from_rubric(rubric)

    # Initialize the results hash
    scores = {}

    # Look for scores for each criterion in the content
    criteria.each do |criterion|
      # Convert criterion to lowercase for case-insensitive matching
      criterion_lower = criterion.downcase

      # Match patterns like "Content: 35/40", "Structure: 28/30", etc.
      match = content.match(/#{Regexp.escape(criterion_lower)}:?\s*(\d+)\/(\d+)/i)

      if match
        # Store the score as an integer
        scores[criterion_lower.to_sym] = match[1].to_i
      end
    end

    scores
  end

  # Extract criteria from the grading rubric
  #
  # @param rubric [String] The grading rubric
  # @return [Array<String>] Array of criteria names
  def extract_criteria_from_rubric(rubric)
    # This is a simple implementation that expects criteria in the format
    # "Criterion: X%" or similar. Adapt as needed for your actual rubric format.
    criteria = []

    # Look for patterns like "Content: 40%", "Grammar: 30%", etc.
    rubric.scan(/([a-zA-Z]+):\s*\d+%/).each do |match|
      criteria << match[0]
    end

    criteria
  end
end
