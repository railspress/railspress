class AddDeletedAtToPostsAndPages < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :deleted_at, :datetime
    add_column :pages, :deleted_at, :datetime
    
    add_index :posts, :deleted_at
    add_index :pages, :deleted_at
  end
end
