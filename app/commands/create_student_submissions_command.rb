# frozen_string_literal: true

# Command to create student submissions for a grading task
#
# This command takes a grading task, fetches documents from the associated
# Google Drive folder, and creates student submissions for each document.
# It encapsulates the document fetching and submission creation logic.
class CreateStudentSubmissionsCommand < BaseCommand
  # Make grading_task explicitly available in the class
  attr_reader :grading_task

  # Initialize the command
  # @param grading_task [GradingTask] The grading task to create submissions for
  def initialize(grading_task:)
    super
  end

  # Execute the command logic
  # @return [Integer] The number of submissions created, or nil if an error occurred
  def execute
    begin
      # Validate the grading task
      unless grading_task.is_a?(GradingTask)
        handle_error("Invalid grading task: must be a GradingTask object")
        return nil
      end

      # Log the operation
      Rails.logger.info("Creating student submissions for grading task #{grading_task.id} (#{grading_task.folder_name})")

      # Fetch documents from Google Drive
      documents = fetch_documents
      return nil unless documents

      # Create student submissions
      submission_count = create_submissions(documents)

      # Return the number of submissions created
      # Note: Even if submission_count is 0, we consider this a success
      # as long as the operation completed without errors
      submission_count
    rescue StandardError => e
      handle_error(e.message)
      nil
    end
  end

  private

  # Fetch documents from the grading task's folder
  # @return [Array<Hash>, nil] Array of documents or nil if failed
  def fetch_documents
    # Get access token for the user
    token_service = GradingTaskAccessTokenService.new(grading_task)
    access_token = token_service.fetch_token

    # Fetch documents from the folder
    document_fetcher = FolderDocumentFetcherService.new(access_token, grading_task.folder_id)
    document_fetcher.fetch
  rescue StandardError => e
    handle_error(e.message)
    nil
  end

  # Create submissions for the documents
  # @param documents [Array<Hash>] Array of document information hashes
  # @return [Integer] The number of submissions created
  def create_submissions(documents)
    # Create a submission creator service
    submission_creator = SubmissionCreatorService.new(grading_task, documents)

    # Create the submissions
    submission_count = submission_creator.create_submissions

    # Log the result
    if submission_count == 0
      Rails.logger.warn("No submissions created from documents for grading task #{grading_task.id}")
    else
      Rails.logger.info("Created #{submission_count} submissions for grading task #{grading_task.id}")
    end

    submission_count
  rescue StandardError => e
    handle_error(e.message)
    nil
  end

  # Handle and log an error
  # @param message [String] The error message
  def handle_error(message)
    Rails.logger.error(message)
    @errors << message
  end
end
