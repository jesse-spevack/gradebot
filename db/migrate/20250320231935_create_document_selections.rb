class CreateDocumentSelections < ActiveRecord::Migration[8.0]
  def change
    create_table :document_selections do |t|
      t.references :grading_task, null: false, foreign_key: true
      t.string :document_id
      t.string :name
      t.string :mime_type

      t.timestamps
    end
  end
end
