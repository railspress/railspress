class AddPasswordToPostsAndPages < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :password, :string
    add_column :posts, :password_hint, :string
    add_column :pages, :password, :string
    add_column :pages, :password_hint, :string
    
    add_index :posts, :password
    add_index :pages, :password
  end
end
