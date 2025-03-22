class RemoveFolderColumnsFromGradingTasks < ActiveRecord::Migration[8.0]
  def change
    remove_column :grading_tasks, :folder_id, :string
    remove_column :grading_tasks, :folder_name, :string
  end
end
