class CreateAssignmentPrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_prompts do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.integer :word_count
      t.string :grade_level
      t.string :subject
      t.date :due_date
      t.references :grading_task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
