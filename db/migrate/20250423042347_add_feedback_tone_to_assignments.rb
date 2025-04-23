class AddFeedbackToneToAssignments < ActiveRecord::Migration[7.1]
  def change
    add_column :assignments, :feedback_tone, :string, null: false, default: 'encouraging'
  end
end
