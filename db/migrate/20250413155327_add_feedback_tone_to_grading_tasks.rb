class AddFeedbackToneToGradingTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :grading_tasks, :feedback_tone, :string
  end
end
