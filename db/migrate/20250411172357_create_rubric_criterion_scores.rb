class CreateRubricCriterionScores < ActiveRecord::Migration[8.0]
  def change
    create_table :rubric_criterion_scores do |t|
      t.references :student_submission, null: false, foreign_key: true
      t.references :criterion, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true
      t.integer :points_earned, null: false
      t.text :reason, null: false
      t.text :evidence, null: false

      t.timestamps
    end
  end
end
