class AddUserAgentAndIpAddressToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :user_agent, :string, null: false
    add_column :sessions, :ip_address, :string, null: false

    # Remove old token and expires_at columns as they're no longer needed
    remove_column :sessions, :token, :string
    remove_column :sessions, :expires_at, :datetime
  end
end
