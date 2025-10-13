class AddPostTypeIdToPosts < ActiveRecord::Migration[7.1]
  def change
    add_reference :posts, :content_type, null: true, foreign_key: true
    add_index :posts, :content_type_id unless index_exists?(:posts, :content_type_id)
  end
end
