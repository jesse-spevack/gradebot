class CreateDocumentSelectionCommand < BaseCommand
  attr_reader :grading_task, :document_data

  def initialize(grading_task:, document_data:)
    super
  end

  private

  def execute
    return [] if document_data.blank?

    document_selection_attributes = document_data.map do |doc|
      {
        document_id: doc["id"],
        name: doc["name"],
        url: doc["url"],
        grading_task_id: grading_task.id
      }
    end

    begin
      DocumentSelection.insert_all(document_selection_attributes)
      data = DocumentSelection.where(grading_task: grading_task)
    rescue StandardError => e
      handle_error(e.message)
      return []
    end

    data
  end
end
