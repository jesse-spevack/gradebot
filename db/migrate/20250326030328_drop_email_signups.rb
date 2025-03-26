class DropEmailSignups < ActiveRecord::Migration[8.0]
  def up
    drop_table :email_signups
  end

  def down
    create_table :email_signups do |t|
      t.string :email, null: false
      t.timestamps
    end
    add_index :email_signups, :email, unique: true
  end
end
