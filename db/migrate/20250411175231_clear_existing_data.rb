class ClearExistingData < ActiveRecord::Migration[8.0]
  # Using up/down instead of change for better control over this destructive operation
  def up
    # Create a utility method to safely delete records and log counts
    clean_tables
  end

  def down
    # Cannot restore deleted data
    puts "WARNING: Cannot restore previously deleted data. This migration is not fully reversible."
    Rails.logger.warn "[Migration Rollback] Attempted to rollback data clearing migration. Data cannot be restored."
  end

  private

  def clean_tables
    # Store counts for logging purposes
    grading_task_count = GradingTask.count
    student_submission_count = StudentSubmission.count
    llm_cost_log_count = LLMCostLog.count

    # Use transactions to ensure atomic operations
    ApplicationRecord.transaction do
      # Clear tables in the correct dependency order to avoid foreign key constraint issues
      # We'll delete all dependent records first, then move up to parent records

      # Clear all child records of student submissions first
      puts "Clearing dependent records..."
      execute("DELETE FROM document_actions")
      execute("DELETE FROM student_submission_checks")
      execute("DELETE FROM strengths WHERE recordable_type = 'StudentSubmission'")
      execute("DELETE FROM opportunities WHERE recordable_type = 'StudentSubmission'")
      execute("DELETE FROM rubric_criterion_scores")

      # Clear all child records of grading tasks
      execute("DELETE FROM strengths WHERE recordable_type = 'GradingTaskSummary'")
      execute("DELETE FROM opportunities WHERE recordable_type = 'GradingTaskSummary'")
      execute("DELETE FROM raw_rubrics")
      execute("DELETE FROM grading_task_summaries")
      execute("DELETE FROM assignment_prompts")

      # Then clean student_submissions
      puts "Clearing student submissions..."
      execute("DELETE FROM student_submissions")

      # Then clean document_selections (now safe since student_submissions are gone)
      puts "Clearing document selections..."
      execute("DELETE FROM document_selections")

      # Clear the grading tasks
      puts "Clearing grading tasks..."
      execute("DELETE FROM grading_tasks")

      # Finally clean llm_cost_logs (no dependencies but clear last for reporting)
      puts "Clearing LLM cost logs..."
      execute("DELETE FROM llm_cost_logs")

      # Log the operation
      Rails.logger.info "[Data Migration] Cleared #{grading_task_count} GradingTasks"
      Rails.logger.info "[Data Migration] Cleared #{student_submission_count} StudentSubmissions"
      Rails.logger.info "[Data Migration] Cleared #{llm_cost_log_count} LLMCostLogs"

      puts "Successfully cleared all existing data:"
      puts "  - #{grading_task_count} GradingTasks"
      puts "  - #{student_submission_count} StudentSubmissions"
      puts "  - #{llm_cost_log_count} LLMCostLogs"
    end
  end
end
