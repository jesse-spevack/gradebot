class CreateFeatureFlagAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_flag_audit_logs do |t|
      t.references :feature_flag, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.boolean :previous_state, null: false
      t.boolean :new_state, null: false
      t.timestamps
    end

    add_index :feature_flag_audit_logs, :created_at
  end
end
