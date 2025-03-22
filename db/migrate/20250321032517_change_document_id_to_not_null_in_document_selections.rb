class ChangeDocumentIdToNotNullInDocumentSelections < ActiveRecord::Migration[8.0]
  def change
    change_column_null :document_selections, :document_id, false
  end
end
