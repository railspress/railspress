class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :slug
      t.text :content
      t.text :excerpt
      t.integer :status
      t.references :user, null: false, foreign_key: true
      t.datetime :published_at
      t.string :featured_image
      t.string :meta_description
      t.string :meta_keywords

      t.timestamps
    end
  end
end
