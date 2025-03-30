class CreateFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :features do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
