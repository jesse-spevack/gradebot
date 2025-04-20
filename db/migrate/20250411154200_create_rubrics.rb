class CreateRubrics < ActiveRecord::Migration[8.0]
  def change
    create_table :rubrics do |t|
      t.string :title
      t.references :user, foreign_key: true
      t.integer :total_points, default: 100
      t.integer :status, default: 0 # enum: 0=pending, 1=processing, 2=complete
      t.timestamps
    end
  end
end
