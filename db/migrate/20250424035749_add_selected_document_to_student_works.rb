class AddSelectedDocumentToStudentWorks < ActiveRecord::Migration[8.0]
  def change
    add_reference :student_works, :selected_document, null: false, foreign_key: true
  end
end
