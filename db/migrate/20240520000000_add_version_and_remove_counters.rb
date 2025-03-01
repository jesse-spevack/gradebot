# frozen_string_literal: true

class AddVersionAndRemoveCounters < ActiveRecord::Migration[7.0]
  def change
    # Add version column to GradingTask for optimistic locking
    add_column :grading_tasks, :lock_version, :integer, default: 0, null: false

    # Add version column to StudentSubmission for optimistic locking
    add_column :student_submissions, :lock_version, :integer, default: 0, null: false

    # Remove counter fields from GradingTask
    remove_column :grading_tasks, :total_count, :integer
    remove_column :grading_tasks, :pending_count, :integer
    remove_column :grading_tasks, :processing_count, :integer
    remove_column :grading_tasks, :completed_count, :integer
    remove_column :grading_tasks, :failed_count, :integer

    # Add index to improve status queries performance
    add_index :student_submissions, [ :grading_task_id, :status ], name: 'index_submissions_on_grading_task_id_and_status'
  end
end
