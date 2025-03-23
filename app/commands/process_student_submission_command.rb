# frozen_string_literal: true

# Command to process a student submission using LLM
class ProcessStudentSubmissionCommand < BaseCommand
  attr_reader :student_submission

  def initialize(student_submission:)
    super
  end

  def execute
    return nil unless student_submission

    begin
      if student_submission.first_attempted_at.nil?
        student_submission.update(first_attempted_at: Time.current)
      end

      student_submission.increment!(:attempt_count)

      return nil unless transition_to_processing

      document_content = fetch_document_content
      return nil unless document_content

      grading_response = grade_submission(document_content: document_content)
      return nil unless grading_response

      update_submission_with_results(
        grading_response: grading_response,
        document_content: document_content
      )

      student_submission.reload
    rescue StandardError => e
      puts "Error processing submission #{student_submission.id}: #{e.message}"
      handle_error(e)
      nil
    end
  end

  private

  # Transition the submission to the processing state
  # @return [Boolean] True if the transition was successful, false otherwise
  def transition_to_processing
    updater = SubmissionStatusUpdater.new(student_submission)
    unless updater.transition_to(:processing)
      @errors << "Could not transition submission to processing state"
      return false
    end
    true
  end

  def fetch_document_content
    google_drive_client = GetGoogleDriveClientForStudentSubmissionCommand.call(
      student_submission: student_submission
    ).result

    DocumentContentFetcherService.new(
      document_id: student_submission.original_doc_id,
      google_drive_client: google_drive_client
    ).fetch
  rescue TokenService::TokenError => e
    Rails.logger.error("Token error for user #{student_submission.grading_task.user.id}: #{e.message}")
    @errors << "Failed to get access token: #{e.message}"

    # Transition to failed state
    SubmissionStatusUpdater.new(student_submission).transition_to(
      :failed,
      { feedback: "Failed to access Google Drive: #{e.message}" }
    )

    nil
  rescue => e
    Rails.logger.error("Error fetching document content: #{e.message}")
    @errors << "Failed to fetch document content: #{e.message}"

    # Transition to failed state - Use the original error message format for test compatibility
    SubmissionStatusUpdater.new(student_submission).transition_to(
      :failed,
      { feedback: "Failed to read document content: #{e.message}" }
    )

    nil
  end

  # Grade the submission using the LLM service
  # @param document_content [String] The content of the document to grade
  # @return [GradingResponse, nil] The grading result or nil if grading failed
  def grade_submission(document_content:)
    orchestrator = GradingOrchestrator.new(
      student_submission: student_submission,
      document_content: document_content
    )

    orchestrator.grade
  rescue LLM::ServiceUnavailableError => e
    # Circuit breaker is open
    Rails.logger.error("Service unavailable: #{e.message}")
    @errors << "Service temporarily unavailable: #{e.message}"

    # Transition to pending state
    SubmissionStatusUpdater.new(student_submission).transition_to(
      :pending,
      {
        feedback: "Grading service temporarily unavailable. Your submission will be automatically retried later."
      }
    )

    # Schedule a retry after the circuit breaker timeout
    # Add 30 seconds buffer to ensure circuit has time to transition to half-open
    retry_after = LLM::CircuitBreaker::TIMEOUT_SECONDS + 30
    StudentSubmissionJob.set(wait: retry_after.seconds).perform_later(student_submission.id)

    nil
  rescue LLM::Errors::AnthropicOverloadError => e
    # Rate limit or overload, but circuit still closed
    Rails.logger.error("API error: #{e.message}")
    @errors << "API temporarily unavailable: #{e.message}"

    # Transition to pending state with retry information
    SubmissionStatusUpdater.new(student_submission).transition_to(
      :pending,
      {
        feedback: "Grading service is busy. Your submission will be automatically retried soon."
      }
    )

    # Schedule a retry after the recommended retry time
    retry_after = e.respond_to?(:retry_after) ? e.retry_after : 60
    StudentSubmissionJob.set(wait: retry_after.seconds).perform_later(student_submission.id)

    nil
  rescue => e
    # Other errors...
    Rails.logger.error("Error during grading: #{e.message}")
    @errors << "Error during grading: #{e.message}"

    # Transition to failed state
    SubmissionStatusUpdater.new(student_submission).transition_to(
      :failed,
      { feedback: "Failed to complete grading: #{e.message.truncate(150)}" }
    )

    nil
  end

  # Update the submission with the grading results
  # @param result [GradingResponse] The grading result
  # @param document_content [String] The content of the document that was graded
  # @return [Boolean] True if the update was successful, false otherwise
  def update_submission_with_results(grading_response:, document_content:)
    # Format the grading results for storage
    formatter = GradeFormatterService.new(grading_response, document_content, student_submission)
    attributes = formatter.format_for_storage

    # Transition to completed state
    SubmissionStatusUpdater.new(student_submission).transition_to(:completed, attributes)
  end

  # Handle any errors that occur during processing
  # @param error [StandardError] The error that occurred
  def handle_error(error)
    Rails.logger.error("Error processing submission #{student_submission.id}: #{error.message}")
    Rails.logger.error(error.backtrace.first(10).join("\n"))
    @errors << error.message
    SubmissionStatusUpdater.new(student_submission).transition_to(
      :failed,
      { feedback: "Processing failed: #{error.message.truncate(150)}" }
    )
  end
end
