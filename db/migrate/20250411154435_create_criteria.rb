class CreateCriteria < ActiveRecord::Migration[8.0]
  def change
    create_table :criteria do |t|
      t.references :rubric, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :points, null: false
      t.integer :position, null: false
      t.timestamps
    end

    add_index :criteria, [ :rubric_id, :position ], unique: true
  end
end
