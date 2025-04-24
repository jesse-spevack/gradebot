# frozen_string_literal: true

# Orchestrates the entire assignment creation process:
# 1. Creates the Assignment record.
# 2. Creates associated SelectedDocument records via SelectedDocument::BulkCreationService.
# 3. Creates associated StudentWork records via StudentWork::BulkCreationService.
# 4. Enqueues AssignmentProcessingJob for background processing.
# Ensures atomicity via ActiveRecord::Base.transaction.
class Assignment::InitializerService
  # Input object for the InitializerService
  # @param current_user [User] The user creating the assignment.
  # @param assignment_params [Hash] Attributes for the Assignment model (e.g., :title, :prompt).
  # @param document_data [Array<Hash>] Array of hashes, each representing a selected Google Doc
  #        (e.g., { google_doc_id: '...', title: '...', url: '...' }).
  Input = Struct.new(:current_user, :assignment_params, :document_data, keyword_init: true)

  attr_reader :input
  attr_reader :assignment # Expose the assignment object

  # @param input [Assignment::InitializerService::Input]
  def initialize(input:)
    @input = input
    @assignment = nil
  end

  # Executes the service logic.
  # @return [Assignment, false] The created Assignment object on success, or false on failure/rollback.
  def call
    # The transaction block's return value is assigned to 'result'
    result = ActiveRecord::Base.transaction do
      @assignment = Assignment.new(input.assignment_params)
      @assignment.user = input.current_user

      unless @assignment.save
        Rails.logger.error "Assignment save failed! Errors: #{@assignment.errors.full_messages.join(', ')}"
        raise ActiveRecord::Rollback # Rolls back and causes the block to return nil
      end

      # 2. Create Selected Documents
      selected_doc_service = SelectedDocument::BulkCreationService.new(
        assignment: @assignment,
        documents_data: input.document_data # Use documents_data consistently
      )
      created_selected_docs = selected_doc_service.call

      # 3. Create Student Works
      StudentWork::BulkCreationService.call(
        assignment: @assignment,
        selected_documents: created_selected_docs
      )

      # 4. Enqueue Job
      AssignmentProcessingJob.perform_later(@assignment.prefix_id)

      @assignment # Explicitly return the assignment if all steps inside succeed
    end # End transaction

    # If transaction succeeded, result is the @assignment object.
    # If ActiveRecord::Rollback was raised, the block returned nil.
    result || false # Return the result (assignment), or false if result is nil

  rescue StandardError => e # Catch errors outside the transaction (less likely now)
    Rails.logger.error "Assignment::InitializerService failed: #{e.message}\n#{e.backtrace.join("\n")}"
    false # Return false on other errors
  end

  private

  attr_reader :input, :assignment
end
