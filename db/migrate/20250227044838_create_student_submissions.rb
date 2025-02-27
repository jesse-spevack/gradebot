class CreateStudentSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :student_submissions do |t|
      t.references :grading_task, null: false, foreign_key: true
      t.string :original_doc_id, null: false
      t.integer :status, null: false, default: 0
      t.text :feedback
      t.string :graded_doc_id

      t.timestamps
    end

    add_index :student_submissions, :status
    add_index :student_submissions, :original_doc_id
  end
end
