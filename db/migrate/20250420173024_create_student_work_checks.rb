class CreateStudentWorkChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :student_work_checks do |t|
      t.text :explanation
      t.integer :check_type, null: false
      t.integer :score, null: false
      t.references :student_work, null: false, foreign_key: true

      t.timestamps
    end
    add_index :student_work_checks, :check_type
  end
end
