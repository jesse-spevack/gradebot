class CreateLlmCostLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_cost_logs do |t|
      t.string :request_type
      t.string :model_name, null: false
      t.integer :prompt_tokens, default: 0
      t.integer :completion_tokens, default: 0
      t.integer :total_tokens, default: 0
      t.decimal :cost, precision: 10, scale: 6, null: false
      t.json :metadata

      # Add foreign key associations
      t.references :user, foreign_key: true, null: true
      t.references :trackable, polymorphic: true, null: true

      t.timestamps
    end

    add_index :llm_cost_logs, :request_type
    add_index :llm_cost_logs, :model_name
    add_index :llm_cost_logs, :created_at
  end
end
