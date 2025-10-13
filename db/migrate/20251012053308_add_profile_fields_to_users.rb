class AddProfileFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :bio, :text unless column_exists?(:users, :bio)
    add_column :users, :website, :string unless column_exists?(:users, :website)
    add_column :users, :twitter, :string unless column_exists?(:users, :twitter)
    add_column :users, :github, :string unless column_exists?(:users, :github)
    add_column :users, :linkedin, :string unless column_exists?(:users, :linkedin)
  end
end
