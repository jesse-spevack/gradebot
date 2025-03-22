class AddDocumentSelectionToStudentSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_reference :student_submissions, :document_selection, null: true, foreign_key: true
  end
end
