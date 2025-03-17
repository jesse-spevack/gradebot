# frozen_string_literal: true

# Service for creating student submissions from Google Drive documents
class SubmissionCreatorService
  # @param grading_task [GradingTask] The grading task to associate with submissions
  # @param documents [Array<Hash>] Array of document information hashes
  def initialize(grading_task, documents)
    @grading_task = grading_task
    @documents = documents
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
        create_submission(document)
        submission_count += 1
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
end
