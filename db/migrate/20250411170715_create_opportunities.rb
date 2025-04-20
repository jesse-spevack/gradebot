class CreateOpportunities < ActiveRecord::Migration[8.0]
  def change
    create_table :opportunities do |t|
      t.references :recordable, polymorphic: true, null: false
      t.text :content, null: false
      t.text :reason, null: false

      t.timestamps
    end
  end
end
