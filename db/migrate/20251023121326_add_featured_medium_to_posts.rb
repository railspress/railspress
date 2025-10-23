class AddFeaturedMediumToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :featured_medium_id, :integer
    add_index :posts, :featured_medium_id
  end
end
