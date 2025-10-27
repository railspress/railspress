class CreateStockPhotoBookmarks < ActiveRecord::Migration[7.1]
  def change
    create_table :stock_photo_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_photo_id, null: false
      t.string :thumbnail_url
      t.string :preview_url
      t.string :download_url
      t.integer :width
      t.integer :height
      t.string :photographer
      t.string :photographer_url
      t.string :source_url
      t.string :alt_description
      t.string :title
      t.text :photo_data

      t.timestamps
    end
    
    add_index :stock_photo_bookmarks, [:user_id, :provider_photo_id], unique: true, name: 'index_bookmarks_on_user_and_provider_id'
  end
end
