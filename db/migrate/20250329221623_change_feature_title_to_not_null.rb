class ChangeFeatureTitleToNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :features, :title, false
  end
end
