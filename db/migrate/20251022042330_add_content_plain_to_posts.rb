class AddContentPlainToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :content_plain, :text
  end
end
