class AddIndexToUsersApiKey < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :api_key, unique: true
  end
end
