class RenameGradingJobsToGradingTasks < ActiveRecord::Migration[8.0]
  def change
    rename_table :grading_jobs, :grading_tasks
  end
end
