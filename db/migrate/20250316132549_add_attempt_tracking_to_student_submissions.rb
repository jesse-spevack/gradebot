class AddAttemptTrackingToStudentSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :student_submissions, :first_attempted_at, :datetime
    add_column :student_submissions, :attempt_count, :integer, default: 0
    add_index :student_submissions, :first_attempted_at
  end
end
