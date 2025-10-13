class AddApiTokenToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true
    add_column :users, :api_requests_count, :integer
    add_column :users, :api_requests_reset_at, :datetime
  end
end
