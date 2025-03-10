# frozen_string_literal: true

# Command to process a grading task by fetching documents and creating submissions
#
# This command takes a grading task ID, fetches documents from the associated
# Google Drive folder, and creates student submissions for each document.
class ProcessGradingTaskCommand < BaseCommand
  attr_reader :grading_task_id

  def initialize(grading_task_id:)
    super
  end

  def execute
    grading_task = find_grading_task
    return nil unless grading_task

    begin
      # Fetch documents from Google Drive
      documents = fetch_documents(grading_task)
      return nil unless documents

      # Create student submissions and enqueue jobs
      create_submissions(documents, grading_task)

      # Return the grading task as the result
      grading_task
    rescue StandardError => e
      handle_error(e.message)
      nil
    end
  end

  private

  # Find the grading task by ID
  # @return [GradingTask, nil] The grading task or nil if not found
  def find_grading_task
    grading_task = GradingTask.find_by(id: grading_task_id)
    unless grading_task
      handle_error("Grading task not found with ID: #{grading_task_id}")
      return nil
    end

    Rails.logger.info("Processing grading task #{grading_task_id} for folder: #{grading_task.folder_name}")
    grading_task
  end

  # Fetch documents from the grading task's folder
  # @param grading_task [GradingTask] The grading task
  # @return [Array<Hash>, nil] Array of documents or nil if failed
  def fetch_documents(grading_task)
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
  # @param grading_task [GradingTask] The grading task
  # @return [Integer] The number of submissions created
  def create_submissions(documents, grading_task)
    submission_creator = SubmissionCreatorService.new(grading_task, documents)
    submission_count = submission_creator.create_submissions

    if submission_count == 0
      handle_error("No submissions created from documents")
    else
      Rails.logger.info("Created #{submission_count} submissions for grading task #{grading_task_id}")
    end

    submission_count
  end

  # Handle and log an error
  # @param message [String] The error message
  def handle_error(message)
    Rails.logger.error(message)
    @errors << message
  end
end
