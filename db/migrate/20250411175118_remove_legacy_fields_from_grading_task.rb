class RemoveLegacyFieldsFromGradingTask < ActiveRecord::Migration[8.0]
  def up
    # Remove legacy fields that are being replaced by the new rubric structure
    # These fields are no longer needed as we now have separate models for this data
    remove_column :grading_tasks, :formatted_grading_rubric, :text
    remove_column :grading_tasks, :grading_rubric, :text
    remove_column :grading_tasks, :assignment_prompt, :text
    remove_column :grading_tasks, :formatted_assignment_prompt, :text

    # Optional: Log that this migration has been run
    Rails.logger.info "[Migration] Removed legacy fields from GradingTask model"
  end

  def down
    # Add the columns back if rolling back, but with no data recovery
    add_column :grading_tasks, :formatted_grading_rubric, :text
    add_column :grading_tasks, :grading_rubric, :text
    add_column :grading_tasks, :assignment_prompt, :text
    add_column :grading_tasks, :formatted_assignment_prompt, :text

    # Log a warning that data has been permanently lost
    Rails.logger.warn "[Migration Rollback] Added back legacy fields to GradingTask model, but data has been permanently lost"
  end
end
