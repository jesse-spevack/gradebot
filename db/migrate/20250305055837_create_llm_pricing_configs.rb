class CreateLLMPricingConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_pricing_configs do |t|
      t.string :llm_model_name, null: false
      t.decimal :prompt_rate, precision: 10, scale: 6, null: false, default: 0
      t.decimal :completion_rate, precision: 10, scale: 6, null: false, default: 0
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :llm_pricing_configs, :llm_model_name, unique: true
  end
end
