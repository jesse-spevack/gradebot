# frozen_string_literal: true

# Orchestrates the bulk creation of selected documents associated with an assignment.
# Handles the creation of multiple selected documents in a single transaction.
class SelectedDocument::BulkCreationService
  MAX_DOCUMENTS = 35

  class TooManyDocumentsError < StandardError; end

  # Params:
  # - assignment: Assignment instance
  # - documents_data: array of hashes with keys :google_doc_id, :url, :title
  #
  # Example:
  #   documents_data = [
  #     { google_doc_id: "abc123", url: "https://docs.google.com/...", title: "Essay 1" },
  #     ...
  #   ]
  def self.call(assignment:, documents_data:)
    new(assignment: assignment, documents_data: documents_data).call
  end

  def initialize(assignment:, documents_data:)
    @assignment = assignment
    @documents_data = documents_data
  end

  def call
    raise TooManyDocumentsError, "Cannot select more than #{MAX_DOCUMENTS} documents" if @documents_data.size > MAX_DOCUMENTS

    values = @documents_data.map do |doc|
      {
        assignment_id: @assignment.id,
        google_doc_id: doc[:id],
        url: doc[:url],
        title: doc[:name]
      }
    end

    # Use insert_all! with returning to get the IDs of the created records
    result = SelectedDocument.insert_all!(values, returning: [ :id ])

    # Fetch the newly created records using the returned IDs
    returned_ids = result.rows.flatten
    SelectedDocument.where(id: returned_ids)
  end
end
