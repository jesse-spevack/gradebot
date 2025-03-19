# frozen_string_literal: true

# Service for creating student submissions from Google Drive documents
class SubmissionCreatorService
  # @param grading_task [GradingTask] The grading task to associate with submissions
  # @param documents [Array<Hash>] Array of document information hashes
  def initialize(grading_task, documents)
    @grading_task = grading_task
    @documents = documents
  end

  # Creates student submissions for documents using bulk insertion
  # @return [Integer] The number of submissions successfully created
  def create_submissions
    return 0 if @documents.empty?

    Rails.logger.info("Creating submissions for #{@documents.length} documents in grading task #{@grading_task.id}")

    # Filter valid documents (only documents and spreadsheets)
    valid_documents = filter_valid_documents

    # Prepare bulk insertion data
    submission_count = bulk_create_submissions(valid_documents)

    Rails.logger.info("Successfully created #{submission_count} submissions for grading task #{@grading_task.id}")
    submission_count
  end

  private

  # Filters documents to only include valid document types
  # @return [Array<Hash>] Array of valid document information hashes
  def filter_valid_documents
    valid_docs = []

    @documents.each do |document|
      # Skip non-document files (like images, PDFs, etc.)
      unless document[:mime_type].include?("document") || document[:mime_type].include?("spreadsheet")
        Rails.logger.info("Skipping non-document file: #{document[:name]} (#{document[:mime_type]}")
        next
      end

      valid_docs << document
    end

    valid_docs
  end

  # Creates student submissions in bulk
  # @param documents [Array<Hash>] Array of document information hashes
  # @return [Integer] The number of submissions created
  def bulk_create_submissions(documents)
    return 0 if documents.empty?

    # Prepare attributes for bulk insertion
    submission_attributes = documents.map do |document|
      {
        grading_task_id: @grading_task.id,
        original_doc_id: document[:id],
        status: StudentSubmission.statuses[:pending],
        metadata: { doc_type: document[:mime_type] },
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    begin
      # Use insert_all! for bulk insertion
      result = StudentSubmission.insert_all!(submission_attributes)
      result.count
    rescue => e
      Rails.logger.error("Failed to bulk create submissions: #{e.message}")

      # Fallback to individual creation if bulk insertion fails
      fallback_create_submissions(documents)
    end
  end

  # Fallback method to create submissions individually if bulk insertion fails
  # @param documents [Array<Hash>] Array of document information hashes
  # @return [Integer] The number of submissions created
  def fallback_create_submissions(documents)
    submission_count = 0

    documents.each do |document|
      begin
        create_submission(document)
        submission_count += 1
      rescue => e
        Rails.logger.error("Failed to create submission for document #{document[:id]}: #{e.message}")
      end
    end

    submission_count
  end

  # Creates a single student submission for a document
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
end
