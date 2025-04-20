class StudentSubmission::BulkCreationService
  class Error < StandardError; end

  def self.call(grading_task:, document_selections:)
    new(grading_task: grading_task, document_selections: document_selections).call
  end

  def initialize(grading_task:, document_selections:)
    @grading_task = grading_task
    @document_selections = document_selections
    @errors = []
  end

  def call
    validate_inputs
    raise Error, @errors.join(", ") if @errors.any?

    create_student_submissions
  end

  private

  def validate_inputs
    @errors << "Grading task is required" unless @grading_task.is_a?(GradingTask)
    @errors << "Document selections are required" if @document_selections.blank?
    @errors << "Document selections must be an array or relation" unless @document_selections.respond_to?(:each)

    if @document_selections&.empty?
      @errors << "At least one document selection is required"
    end
  end

  def create_student_submissions
    return [] if @document_selections.empty?

    timestamp = Time.current
    bulk_data = @document_selections.map do |document_selection|
      {
        grading_task_id: @grading_task.id,
        document_selection_id: document_selection.id,
        status: "pending",
        created_at: timestamp,
        updated_at: timestamp
      }
    end

    begin
      ActiveRecord::Base.transaction do
        StudentSubmission.insert_all(bulk_data, returning: %w[id])
      end
    rescue => e
      @errors << "Failed to create student submissions: #{e.message}"
      raise Error, @errors.join(", ")
    end

    # Return all student submissions for this grading task that match the document selections
    StudentSubmission.where(
      grading_task: @grading_task,
      document_selection_id: @document_selections.map(&:id)
    )
  end
end
