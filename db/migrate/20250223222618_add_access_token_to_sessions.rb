class AddAccessTokenToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :access_token, :string
  end
end
