class CreateFeedbackItems < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_items do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.text :evidence
      t.integer :kind, null: false
      t.references :feedbackable, polymorphic: true, null: false

      t.timestamps
    end
    add_index :feedback_items, :kind
  end
end
