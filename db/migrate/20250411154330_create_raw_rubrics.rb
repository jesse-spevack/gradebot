class CreateRawRubrics < ActiveRecord::Migration[8.0]
  def change
    create_table :raw_rubrics do |t|
      t.text :content, null: false
      t.references :grading_task, null: false, foreign_key: true
      t.references :rubric, foreign_key: true
      t.timestamps
    end
  end
end
