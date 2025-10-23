class AddContentJsonToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :content_json, :text
  end
end
