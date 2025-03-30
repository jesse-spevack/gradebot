class AddReleaseDateToFeatures < ActiveRecord::Migration[8.0]
  def change
    add_column :features, :release_date, :date
  end
end
