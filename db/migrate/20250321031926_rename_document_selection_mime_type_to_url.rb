class RenameDocumentSelectionMimeTypeToUrl < ActiveRecord::Migration[8.0]
  def change
    rename_column :document_selections, :mime_type, :url
  end
end
