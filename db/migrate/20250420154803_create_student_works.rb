class CreateStudentWorks < ActiveRecord::Migration[8.0]
  def change
    create_table :student_works do |t|
      t.text :qualitative_feedback
      t.references :assignment, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :student_works, :status
  end
end
