class CreateGradingJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :grading_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.text :assignment_prompt
      t.string :folder_id
      t.string :folder_name

      t.timestamps
    end
  end
end
