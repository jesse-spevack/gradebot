# frozen_string_literal: true

# Command to create student submissions for a grading task
#
# This command takes a grading task and document selections,
# and creates student submissions for each document selection.
# It encapsulates the submission creation logic.
class CreateStudentSubmissionsCommand < BaseCommand
  # Make grading_task and document_selections explicitly available in the class
  attr_reader :grading_task, :document_selections

  # Initialize the command
  # @param grading_task [GradingTask] The grading task to create submissions for
  # @param document_selections [Array<DocumentSelection>] The document selections to create submissions from
  def initialize(grading_task:, document_selections:)
    super
  end

  # Execute the command logic
  # @return [Integer] The number of submissions created, or nil if an error occurred
  def execute
    begin
      # Validate the grading task
      unless grading_task.is_a?(GradingTask)
        handle_error("Invalid grading task: must be a GradingTask object")
        return nil
      end

      # Log the operation
      Rails.logger.info("Creating student submissions for grading task #{grading_task.id}")

      # Validate document selections
      if document_selections.blank?
        Rails.logger.warn("No document selections provided for grading task #{grading_task.id}")
        return 0
      end

      # Create student submissions
      submission_count = create_submissions

      # Return the number of submissions created
      # Note: Even if submission_count is 0, we consider this a success
      # as long as the operation completed without errors
      submission_count
    rescue StandardError => e
      handle_error(e.message)
      nil
    end
  end

  private
  # Create submissions for the document selections
  # @return [Integer] The number of submissions created
  def create_submissions
    submission_count = 0

    student_submission_attributes = document_selections.map do |document_selection|
      {
        grading_task_id: grading_task.id,
        original_doc_id: document_selection.document_id,
        status: "pending"
      }
    end

    StudentSubmission.insert_all(student_submission_attributes)

    submission_count
  end

  # Handle and log an error
  # @param message [String] The error message
  def handle_error(message)
    Rails.logger.error(message)
    @errors << message
  end
end
