class CreateGradingTaskSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :grading_task_summaries do |t|
      t.references :grading_task, null: false, foreign_key: true
      t.integer :submissions_count, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :insights

      t.timestamps
    end
  end
end
