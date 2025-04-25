# frozen_string_literal: true

# Orchestrates the entire assignment creation process:
# 1. Creates the Assignment record.
# 2. Creates associated SelectedDocument records via SelectedDocument::BulkCreationService.
# 3. Creates associated StudentWork records via StudentWork::BulkCreationService.
# 4. Enqueues AssignmentProcessingJob for background processing.
# Ensures atomicity via ActiveRecord::Base.transaction.
class Assignment::InitializerService
  # @param input [Assignment::InitializerService::Input]
  def self.call(input:)
    new(input: input).call
  end

  attr_reader :input

  # @param input [Assignment::InitializerService::Input]
  def initialize(input:)
    @input = input
  end

  # Executes the service logic.
  # @return [Assignment, false] The created Assignment object on success, or false on failure/rollback.
  def call
    # The transaction block's return value is assigned to 'result'
    Rails.logger.info "Creating new assignment for user #{input.current_user.id}"
    result = ActiveRecord::Base.transaction do
      @assignment = Assignment.new(
        user: input.current_user,
        title: input.title,
        subject: input.subject,
        grade_level: input.grade_level,
        description: input.description,
        instructions: input.instructions,
        feedback_tone: input.feedback_tone,
        raw_rubric_text: input.raw_rubric_text
      )

      unless @assignment.save
        Rails.logger.error "Assignment save failed! Errors: #{@assignment.errors.full_messages.join(', ')}"
        raise ActiveRecord::Rollback # Rolls back and causes the block to return nil
      end

      # 2. Create Selected Documents
      created_selected_docs = SelectedDocument::BulkCreationService.call(
        assignment: @assignment,
        documents_data: input.document_data # Use documents_data consistently
      )

      # 3. Create Student Works
      StudentWork::BulkCreationService.call(
        assignment: @assignment,
        selected_documents: created_selected_docs
      )

      # 4. Enqueue Job
      AssignmentProcessingJob.perform_later(@assignment.id)

      @assignment
    end # End transaction

    # If transaction succeeded, result is the @assignment object.
    # If ActiveRecord::Rollback was raised, the block returned nil.
    result || false # Return the result (assignment), or false if result is nil

  rescue StandardError => e # Catch errors outside the transaction (less likely now)
    Rails.logger.error "Assignment::InitializerService failed: #{e.message}\n#{e.backtrace.join("\n")}"
    false # Return false on other errors
  end
end
