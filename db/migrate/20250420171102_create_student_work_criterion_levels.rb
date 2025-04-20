class CreateStudentWorkCriterionLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :student_work_criterion_levels do |t|
      t.text :explanation
      t.references :student_work, null: false, foreign_key: true
      t.references :criterion, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true

      t.timestamps
    end

    add_index :student_work_criterion_levels, [ :student_work_id, :criterion_id ], unique: true, name: 'index_swcl_on_student_work_and_criterion'
  end
end
