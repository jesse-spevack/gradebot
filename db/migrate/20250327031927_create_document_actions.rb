class CreateDocumentActions < ActiveRecord::Migration[8.0]
  def change
    create_table :document_actions do |t|
      t.references :student_submission, null: false, foreign_key: true
      t.integer :action_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :error_message
      t.datetime :completed_at
      t.datetime :failed_at

      t.timestamps
    end

  add_index :document_actions, [ :student_submission_id, :action_type ]
  add_index :document_actions, :status
  end
end
