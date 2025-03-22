# frozen_string_literal: true

class CreateStudentSubmissionsCommand < CommandBase
  def execute
    begin
      unless grading_task.is_a?(GradingTask)
        handle_error("Invalid grading task: must be a GradingTask object")
        return nil
      end

      Rails.logger.info("Creating student submissions for grading task #{grading_task.id}")

      unless document_selections.all? { |document_selection| document_selection.is_a?(DocumentSelection) }
        handle_error("Invalid document selections: must be an array of DocumentSelection objects")
        return nil
      end

      create_submissions
    rescue StandardError => e
      handle_error(e.message)
      nil
    end
  end

  private
  # Create submissions for the document selections
  def create_submissions
    student_submission_attributes = document_selections.map do |document_selection|
      {
        grading_task_id: grading_task.id,
        original_doc_id: document_selection.document_id,
        status: "pending"
      }
    end

    StudentSubmission.insert_all(student_submission_attributes)
    StudentSubmission.where(document_selection: document_selections)
  end

  # Handle and log an error
  # @param message [String] The error message
  def handle_error(message)
    Rails.logger.error(message)
    @errors << message
  end
end
