# frozen_string_literal: true

# Service for creating student submissions from Google Drive documents
class SubmissionCreatorService
  # @param grading_task [GradingTask] The grading task to associate with submissions
  # @param documents [Array<Hash>] Array of document information hashes
  # @param enqueue_jobs [Boolean] Whether to enqueue processing jobs for each submission
  def initialize(grading_task, documents, enqueue_jobs: true)
    @grading_task = grading_task
    @documents = documents
    @enqueue_jobs = enqueue_jobs
  end

  # Creates student submissions for documents
  # @return [Integer] The number of submissions successfully created
  def create_submissions
    return 0 if @documents.empty?

    Rails.logger.info("Creating submissions for #{@documents.length} documents in grading task #{@grading_task.id}")

    submission_count = 0

    @documents.each do |document|
      # Skip non-document files (like images, PDFs, etc.)
      unless document[:mime_type].include?("document") || document[:mime_type].include?("spreadsheet")
        Rails.logger.info("Skipping non-document file: #{document[:name]} (#{document[:mime_type]})")
        next
      end

      begin
        # Create the submission record
        submission = create_submission(document)
        submission_count += 1

        # Enqueue a job to process the submission if requested
        enqueue_processing_job(submission)
      rescue => e
        Rails.logger.error("Failed to create submission for document #{document[:id]}: #{e.message}")
      end
    end

    Rails.logger.info("Successfully created #{submission_count} submissions for grading task #{@grading_task.id}")
    submission_count
  end

  private

  # Creates a student submission for a document
  # @param document [Hash] Document information hash
  # @return [StudentSubmission] The created submission
  def create_submission(document)
    StudentSubmission.create!(
      grading_task: @grading_task,
      original_doc_id: document[:id],
      status: :pending,
      metadata: { doc_type: document[:mime_type] }
    )
  end

  # Enqueues a job to process the student submission
  # @param submission [StudentSubmission] The submission to process
  def enqueue_processing_job(submission)
    return unless @enqueue_jobs

    Rails.logger.info("Enqueuing processing job for submission #{submission.id}")
    StudentSubmissionJob.perform_later(submission.id)
  end
end
