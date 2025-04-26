# frozen_string_literal: true

# Orchestrates the bulk creation of selected documents associated with an assignment.
# Handles the creation of multiple selected documents in a single transaction.
class SelectedDocument::BulkCreationService
  MAX_DOCUMENTS = 35

  class TooManyDocumentsError < StandardError; end

  # Params:
  # - assignment: Assignment instance
  # - documents_data: array of OpenStruct instances with keys :google_doc_id, :url, :title
  def self.call(assignment:, documents_data:)
    new(assignment: assignment, documents_data: documents_data).call
  end

  def initialize(assignment:, documents_data:)
    @assignment = assignment
    @documents_data = documents_data
  end

  def call
    raise TooManyDocumentsError, "Cannot select more than #{MAX_DOCUMENTS} documents" if @documents_data.size > MAX_DOCUMENTS


    values = @documents_data.map do |document_data|
      {
        assignment_id: @assignment.id,
        title: document_data.title,
        google_doc_id: document_data.google_doc_id,
        url: document_data.url
      }
    end

    Rails.logger.warn("Values\n\n: #{values}")

    # Use insert_all! with returning to get the IDs of the created records
    begin
    result = SelectedDocument.insert_all!(values, returning: [ :id ])
    rescue StandardError => e
      Rails.logger.error "Failed to create selected documents: #{e.message}"

      raise
    end

    # Fetch the newly created records using the returned IDs
    returned_ids = result.rows.flatten
    SelectedDocument.where(id: returned_ids)
  end
end
