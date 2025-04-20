class DocumentSelection::BulkCreationService
  class Error < StandardError; end

  def self.call(grading_task:, document_data:)
    new(grading_task: grading_task, document_data: document_data).call
  end

  def initialize(grading_task:, document_data:)
    @grading_task = grading_task
    @document_data = document_data.is_a?(DocumentDataCollection) ? document_data : DocumentDataCollection.new(document_data)
    @errors = []
  end

  def call
    validate_inputs
    raise Error, @errors.join(", ") if @errors.any?

    create_document_selections
  end

  private

  def validate_inputs
    @errors << "Grading task is required" unless @grading_task.is_a?(GradingTask)

    unless @document_data.valid?
      @document_data.errors.full_messages.each do |message|
        @errors << message
      end
    end
  end

  def create_document_selections
    return [] if @document_data.empty?

    bulk_data = @document_data.to_selection_params(@grading_task.id)

    begin
      ActiveRecord::Base.transaction do
        DocumentSelection.insert_all(bulk_data, returning: %w[id])
      end

    rescue => e
      @errors << "Failed to create document selections: #{e.message}"
      raise Error, @errors.join(", ")
    end

    DocumentSelection.where(grading_task: @grading_task)
  end
end
