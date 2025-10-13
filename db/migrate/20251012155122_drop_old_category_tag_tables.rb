class DropOldCategoryTagTables < ActiveRecord::Migration[7.1]
  def up
    # Drop join tables first (they have foreign keys)
    drop_table :post_tags if table_exists?(:post_tags)
    drop_table :post_categories if table_exists?(:post_categories)
    
    # Then drop the main tables
    drop_table :tags if table_exists?(:tags)
    drop_table :categories if table_exists?(:categories)
    
    say "✅ Dropped old category and tag tables"
    say "  - categories"
    say "  - tags"
    say "  - post_categories"
    say "  - post_tags"
  end
  
  def down
    # Recreate tables if migration is rolled back
    create_table :categories do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.integer :parent_id
      t.timestamps
    end
    add_index :categories, :parent_id
    add_index :categories, :slug, unique: true
    
    create_table :tags do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.timestamps
    end
    add_index :tags, :slug, unique: true
    
    create_table :post_categories do |t|
      t.references :post, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.timestamps
    end
    add_index :post_categories, [:post_id, :category_id], unique: true
    
    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :post_tags, [:post_id, :tag_id], unique: true
  end
end
