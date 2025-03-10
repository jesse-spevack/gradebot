# frozen_string_literal: true

# Command to process a student submission using LLM
#
# This command takes a student submission ID, retrieves the submission,
# and processes it to generate feedback using the LLM framework.
class ProcessStudentSubmissionCommand < BaseCommand
  # Make student_submission_id explicitly available in the class
  attr_reader :student_submission_id

  def initialize(student_submission_id:)
    super
  end

  # Execute the command logic
  # Orchestrates the process of fetching document content and grading a submission
  #
  # @return [StudentSubmission] The processed student submission
  def execute
    submission = find_submission
    return nil unless submission

    begin
      # Transition to processing state
      return nil unless transition_to_processing(submission)

      # Fetch document content
      document_content = fetch_document_content(submission)
      return nil unless document_content

      # Grade the submission
      grading_result = grade_submission(submission, document_content)
      return nil unless grading_result

      # Update the submission with the grading results
      update_submission_with_results(submission, grading_result, document_content)

      # Return the processed submission
      submission
    rescue StandardError => e
      handle_error(submission, e)
      nil
    end
  end

  private

  # Find the student submission by ID
  # @return [StudentSubmission, nil] The student submission or nil if not found
  def find_submission
    submission = StudentSubmission.find_by(id: student_submission_id)
    unless submission
      @errors << "Student submission not found with ID: #{student_submission_id}"
      return nil
    end
    submission
  end

  # Transition the submission to the processing state
  # @param submission [StudentSubmission] The submission to transition
  # @return [Boolean] True if the transition was successful, false otherwise
  def transition_to_processing(submission)
    updater = SubmissionStatusUpdater.new(submission)
    unless updater.transition_to(:processing)
      @errors << "Could not transition submission to processing state"
      return false
    end
    true
  end

  # Fetch document content for the submission
  # @param submission [StudentSubmission] The submission to fetch content for
  # @return [String, nil] The document content or nil if fetching failed
  def fetch_document_content(submission)
    DocumentFetcherService.new(submission).fetch
  rescue TokenService::TokenError => e
    Rails.logger.error("Token error for user #{submission.grading_task.user.id}: #{e.message}")
    @errors << "Failed to get access token: #{e.message}"

    # Transition to failed state
    SubmissionStatusUpdater.new(submission).transition_to(
      :failed,
      { feedback: "Failed to access Google Drive: #{e.message}" }
    )

    nil
  rescue => e
    Rails.logger.error("Error fetching document content: #{e.message}")
    @errors << "Failed to fetch document content: #{e.message}"

    # Transition to failed state - Use the original error message format for test compatibility
    SubmissionStatusUpdater.new(submission).transition_to(
      :failed,
      { feedback: "Failed to read document content: #{e.message}" }
    )

    nil
  end

  # Grade the submission using the LLM service
  # @param submission [StudentSubmission] The submission to grade
  # @param document_content [String] The content of the document to grade
  # @return [GradingResponse, nil] The grading result or nil if grading failed
  def grade_submission(submission, document_content)
    orchestrator = GradingOrchestrator.new(
      submission: submission,
      document_content: document_content
    )

    orchestrator.grade
  rescue => e
    Rails.logger.error("Error during grading: #{e.message}")
    @errors << "Error during grading: #{e.message}"

    # Transition to failed state
    SubmissionStatusUpdater.new(submission).transition_to(
      :failed,
      { feedback: "Failed to complete grading: #{e.message.truncate(150)}" }
    )

    nil
  end

  # Update the submission with the grading results
  # @param submission [StudentSubmission] The submission to update
  # @param result [GradingResponse] The grading result
  # @param document_content [String] The content of the document that was graded
  # @return [Boolean] True if the update was successful, false otherwise
  def update_submission_with_results(submission, result, document_content)
    # Format the grading results for storage
    formatter = GradeFormatterService.new(result, document_content, submission)
    attributes = formatter.format_for_storage

    # Transition to completed state
    SubmissionStatusUpdater.new(submission).transition_to(:completed, attributes)
  end

  # Handle any errors that occur during processing
  # @param submission [StudentSubmission] The submission being processed
  # @param error [StandardError] The error that occurred
  def handle_error(submission, error)
    Rails.logger.error("Error processing submission #{student_submission_id}: #{error.message}")
    Rails.logger.error(error.backtrace.first(10).join("\n"))
    @errors << error.message

    return unless submission

    # Transition to failed state
    SubmissionStatusUpdater.new(submission).transition_to(
      :failed,
      { feedback: "Processing failed: #{error.message.truncate(150)}" }
    )
  end
end
