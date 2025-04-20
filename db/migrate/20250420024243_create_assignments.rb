class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.string :title, null: false
      t.text :description
      t.string :grade_level, null: false
      t.string :subject, null: false
      t.text :instructions
      t.text :raw_rubric_text
      t.integer :total_processing_milliseconds
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
