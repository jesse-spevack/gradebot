# frozen_string_literal: true

# Job to handle background processing for an assignment after creation.
# (e.g., fetching document content, initial analysis)
class AssignmentProcessingJob < ApplicationJob
  queue_as :default

  # @param assignment_id [String] The ID of the assignment to process.
  def perform(assignment_id)
    # TODO: Implement assignment processing logic
    Rails.logger.info "AssignmentProcessingJob started for Assignment ID: #{assignment_id}"
    # Example: Find assignment
    # assignment = Assignment.find_by_prefix_id(assignment_id)
    # return unless assignment
    # ... processing logic ...
    Rails.logger.info "AssignmentProcessingJob finished for Assignment ID: #{assignment_id}"
  end
end
