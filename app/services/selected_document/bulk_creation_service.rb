# frozen_string_literal: true

class SelectedDocument::BulkCreationService
  MAX_DOCUMENTS = 35

  class TooManyDocumentsError < StandardError; end

  # Params:
  # - assignment: Assignment instance
  # - documents: array of hashes with keys :google_doc_id, :url, :title
  #
  # Example:
  #   documents = [
  #     { google_doc_id: "abc123", url: "https://docs.google.com/...", title: "Essay 1" },
  #     ...
  #   ]
  def initialize(assignment:, documents:)
    @assignment = assignment
    @documents = documents
  end

  def call
    raise TooManyDocumentsError, "Cannot select more than #{MAX_DOCUMENTS} documents" if @documents.size > MAX_DOCUMENTS

    values = @documents.map do |doc|
      {
        assignment_id: @assignment.id,
        google_doc_id: doc[:google_doc_id],
        url: doc[:url],
        title: doc[:title]
      }
    end

    SelectedDocument.insert_all!(values)
  end
end
