class CreateLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :levels do |t|
      t.string :title, null: false
      t.text :description
      t.integer :position
      t.references :criterion, null: false, foreign_key: true

      t.timestamps
    end
  end
end
