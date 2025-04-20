class ReplaceRichTextWithPlainText < ActiveRecord::Migration[8.0]
  def change
    # Simply add a text column to assignment_prompts
    add_column :assignment_prompts, :content, :text
  end
end
