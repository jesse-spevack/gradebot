class CreateLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :levels do |t|
      t.references :criterion, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :points, null: false
      t.integer :position, null: false
      t.timestamps
    end

    add_index :levels, [ :criterion_id, :position ], unique: true
  end
end
