class RemoveUniqueIndexFromSelectedDocumentsGoogleDocId < ActiveRecord::Migration[7.1]
  def change
    remove_index :selected_documents, name: "index_selected_documents_on_google_doc_id"
    add_index :selected_documents, :google_doc_id
  end
end
