# frozen_string_literal: true

class RemoveTokenFieldsFromUsers < ActiveRecord::Migration[8.0]
  def change
    # Remove token fields from users table since they're now stored in user_tokens
    remove_column :users, :access_token, :string
    remove_column :users, :refresh_token, :string
    remove_column :users, :token_expires_at, :datetime
  end
end
