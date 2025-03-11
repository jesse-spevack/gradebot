class AddFormattedFieldsToGradingTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :grading_tasks, :formatted_assignment_prompt, :text
    add_column :grading_tasks, :formatted_grading_rubric, :text
  end
end
