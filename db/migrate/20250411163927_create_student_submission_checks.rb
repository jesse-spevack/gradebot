class CreateStudentSubmissionChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :student_submission_checks do |t|
      t.references :student_submission, null: false, foreign_key: true
      t.integer :check_type, null: false
      t.integer :score, null: false
      t.text :reason, null: false

      t.timestamps
    end
  end
end
