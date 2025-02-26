class CreateFeatureFlags < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_flags do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :enabled, default: false, null: false
      t.datetime :last_changed_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end
    add_index :feature_flags, :key, unique: true
  end
end
