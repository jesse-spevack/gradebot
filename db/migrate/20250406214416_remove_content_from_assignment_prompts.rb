class RemoveContentFromAssignmentPrompts < ActiveRecord::Migration[8.0]
  def change
    remove_column :assignment_prompts, :content, :text
  end
end
