class CreateSelectedDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :selected_documents do |t|
      t.string :google_doc_id, null: false
      t.string :title, null: false
      t.string :url, null: false
      t.references :assignment, null: false, foreign_key: true

      t.timestamps
    end
    add_index :selected_documents, :google_doc_id, unique: true
  end
end
