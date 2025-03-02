# frozen_string_literal: true

# Command to process a grading task using LLM
#
# This command takes a grading task ID, retrieves the task,
# fetches documents from the associated Google Drive folder,
# creates StudentSubmission records, and enqueues jobs to process each submission.
class ProcessGradingTaskCommand < BaseCommand
  # Make grading_task_id explicitly available in the class
  attr_reader :grading_task_id

  def initialize(grading_task_id:)
    super
  end

  private

  # Execute the command logic
  # 1. Find the grading task by ID
  # 2. Fetch documents from the Google Drive folder
  # 3. Create StudentSubmission records for each document
  # 4. Enqueue a job to process each submission
  #
  # @return [GradingTask] The processed grading task
  def execute
    # Find the grading task by ID
    grading_task = GradingTask.find_by(id: grading_task_id)

    unless grading_task
      handle_error("Grading task not found with ID: #{grading_task_id}")
      return nil
    end

    # Log the task ID and folder
    Rails.logger.info("Processing grading task #{grading_task_id} for folder: #{grading_task.folder_name}")

    # Fetch documents from Google Drive
    documents = fetch_documents_from_folder(grading_task.folder_id)

    # Create student submissions and enqueue jobs
    process_documents(documents, grading_task)

    # Return the grading task as the result
    grading_task
  end

  # Fetch documents from the specified Google Drive folder
  #
  # @param folder_id [String] The ID of the Google Drive folder
  # @return [Array<Hash>] Array of document information hashes
  def fetch_documents_from_folder(folder_id)
    # Use the GoogleDriveService to fetch documents
    service = GoogleDriveService.new(access_token)
    service.list_files_in_folder(folder_id)
  rescue GoogleDriveService::Error => e
    handle_error("Failed to fetch documents: #{e.message}")
    []
  end

  # Process documents by creating student submissions and enqueuing jobs
  #
  # @param documents [Array<Hash>] Array of document information hashes
  # @param grading_task [GradingTask] The grading task to associate with submissions
  # @return [Integer] The number of submissions created
  def process_documents(documents, grading_task)
    if documents.empty?
      handle_error("No documents found in folder")
      return 0
    end

    created_count = 0

    # Create a student submission for each document
    documents.each do |doc|
      # Start a transaction to ensure consistent state
      ActiveRecord::Base.transaction do
        # Create the submission record with initial status
        submission = StudentSubmission.new(
          grading_task: grading_task,
          original_doc_id: doc[:id],
          status: :pending
        )

        # Save the record
        submission.save!

        # Update the grading task status to reflect the new submission
        # This will also update any internal status tracking
        StatusManager.update_grading_task_status(grading_task)

        # Enqueue a job to process this submission
        StudentSubmissionJob.perform_later(submission.id)
      end

      created_count += 1
    end

    Rails.logger.info("Created #{created_count} student submissions for grading task #{grading_task.id}")
    created_count
  end

  # Get the access token for Google Drive API
  #
  # @return [String] The access token
  def access_token
    # Get the user associated with this grading task
    grading_task = GradingTask.find_by(id: grading_task_id)

    if !grading_task || !grading_task.user
      Rails.logger.error("Could not find grading task or its user for task ID: #{grading_task_id}")
      return nil
    end

    # Use the TokenService to get a valid token
    token_service = TokenService.new(grading_task.user)

    begin
      token_service.access_token
    rescue TokenService::TokenError => e
      Rails.logger.error("Token error for user #{grading_task.user.id}: #{e.message}")
      handle_error("Failed to get access token: #{e.message}")
      nil
    end
  end
end
