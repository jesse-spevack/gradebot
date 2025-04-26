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
        raise ActiveRecord::Rollback
      end

      created_selected_docs = SelectedDocument::BulkCreationService.call(
        assignment: @assignment,
        documents_data: input.document_data
      )

      StudentWork::BulkCreationService.call(
        assignment: @assignment,
        selected_documents: created_selected_docs
      )

      AssignmentProcessingJob.perform_later(@assignment.id)

      @assignment
    end

    result || false
  rescue StandardError => e
    Rails.logger.error "Assignment::InitializerService failed: #{e.message}\n#{e.backtrace.join("\n")}"
    false
  end
end
