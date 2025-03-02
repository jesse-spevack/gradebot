class CreateUserTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :user_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.text :scopes

      t.timestamps
    end
  end
end
