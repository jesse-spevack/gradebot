class AddGradingDetailsToStudentSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :student_submissions, :strengths, :text
    add_column :student_submissions, :opportunities, :text
    add_column :student_submissions, :overall_grade, :string
    add_column :student_submissions, :rubric_scores, :json
    add_column :student_submissions, :metadata, :json
  end
end
