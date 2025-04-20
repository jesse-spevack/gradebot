class CreateRubrics < ActiveRecord::Migration[8.0]
  def change
    create_table :rubrics do |t|
      t.string :title, null: false
      t.text :description
      t.references :assignment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
