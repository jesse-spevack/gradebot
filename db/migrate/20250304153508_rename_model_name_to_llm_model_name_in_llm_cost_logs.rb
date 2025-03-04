class RenameModelNameToLLMModelNameInLLMCostLogs < ActiveRecord::Migration[8.0]
  def change
    rename_column :llm_cost_logs, :model_name, :llm_model_name
  end
end
