class RemoveLegacyFieldsFromStudentSubmissions < ActiveRecord::Migration[8.0]
  def change
    remove_column :student_submissions, :graded_doc_id, :string
    remove_column :student_submissions, :strengths, :text
    remove_column :student_submissions, :opportunities, :text
    remove_column :student_submissions, :rubric_scores, :text
    remove_column :student_submissions, :metadata, :json
    remove_column :student_submissions, :first_attempted_at, :datetime
    remove_column :student_submissions, :attempt_count, :integer
    remove_column :student_submissions, :original_doc_id, :string
  end
end
