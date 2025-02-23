class CreateEmailSignups < ActiveRecord::Migration[8.0]
  def change
    create_table :email_signups do |t|
      t.string :email

      t.timestamps
    end
    add_index :email_signups, :email, unique: true
  end
end
