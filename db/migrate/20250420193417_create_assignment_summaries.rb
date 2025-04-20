class CreateAssignmentSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_summaries do |t|
      t.integer :student_work_count, null: false, default: 0
      t.text :qualitative_insights, null: false
      t.references :assignment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
