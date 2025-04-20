class AddRubricToGradingTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :grading_tasks, :rubric, null: true, foreign_key: true, index: true
  end
end
