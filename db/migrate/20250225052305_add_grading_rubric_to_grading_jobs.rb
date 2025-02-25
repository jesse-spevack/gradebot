class AddGradingRubricToGradingJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :grading_jobs, :grading_rubric, :text
  end
end
