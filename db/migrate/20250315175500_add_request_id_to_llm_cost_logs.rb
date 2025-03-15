class AddRequestIdToLLMCostLogs < ActiveRecord::Migration[8.0]
  def change
    # Add request_id column if it doesn't exist
    unless column_exists?(:llm_cost_logs, :request_id)
      add_column :llm_cost_logs, :request_id, :string
      add_index :llm_cost_logs, :request_id
    end
  end
end
