class AddStatusCountersToGradingTask < ActiveRecord::Migration[8.0]
  def change
    add_column :grading_tasks, :status, :integer, default: 0
    add_column :grading_tasks, :pending_count, :integer, default: 0
    add_column :grading_tasks, :processing_count, :integer, default: 0
    add_column :grading_tasks, :completed_count, :integer, default: 0
    add_column :grading_tasks, :failed_count, :integer, default: 0
    add_column :grading_tasks, :total_count, :integer, default: 0
  end
end
