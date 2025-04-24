# frozen_string_literal: true

# Creates multiple StudentWork records from SelectedDocument records
# within a single database transaction.
class StudentWork::BulkCreationService
  def self.call(assignment:, selected_documents:)
    new(assignment: assignment, selected_documents: selected_documents).call
  end

  attr_reader :assignment, :selected_documents

  # @param assignment [Assignment] The assignment these student works belong to.
  # @param selected_documents [Array<SelectedDocument>] The documents to create work records for.
  def initialize(assignment:, selected_documents:)
    @assignment = assignment
    @selected_documents = selected_documents
  end

  # Executes the bulk creation process.
  # @return [Boolean] true if successful, false otherwise (or raises error)
  def call
    student_works_attributes = selected_documents.map do |doc|
      {
        assignment_id: assignment.id,
        selected_document_id: doc.id,
        status: StudentWork.statuses[:pending]
      }
    end

    return false if student_works_attributes.empty?

    # Although insert_all is atomic, keep transaction for explicit control
    # and potential future steps within the same transaction.
    ActiveRecord::Base.transaction do
      StudentWork.insert_all(student_works_attributes)
    end

    true # Return true on success
  rescue StandardError => e # Catch potential DB errors from insert_all
    # Log error or handle as needed
    Rails.logger.error "StudentWork bulk creation failed during insert_all: #{e.message}"
    false # Return false on failure
  end
end
