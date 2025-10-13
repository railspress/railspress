class CreatePageviews < ActiveRecord::Migration[7.1]
  def change
    create_table :pageviews do |t|
      t.string :path, null: false
      t.string :title
      t.string :referrer
      t.string :user_agent
      t.string :browser
      t.string :device
      t.string :os
      t.string :country_code
      t.string :city
      t.string :region
      t.string :ip_hash  # Hashed IP for privacy
      t.string :session_id
      t.integer :user_id
      t.integer :post_id
      t.integer :page_id
      t.integer :duration  # Time spent on page (seconds)
      t.boolean :unique_visitor, default: false
      t.boolean :returning_visitor, default: false
      t.boolean :bot, default: false
      t.boolean :consented, default: false
      t.text :metadata  # JSON storage for additional data
      t.integer :tenant_id
      t.datetime :visited_at, null: false

      t.timestamps
    end
    
    # Performance indexes
    add_index :pageviews, :path
    add_index :pageviews, :visited_at
    add_index :pageviews, :session_id
    add_index :pageviews, :tenant_id
    add_index :pageviews, :country_code
    add_index :pageviews, :user_id
    add_index :pageviews, :post_id
    add_index :pageviews, :page_id
    add_index :pageviews, [:tenant_id, :visited_at]
    add_index :pageviews, [:path, :visited_at]
    add_index :pageviews, :bot
    add_index :pageviews, :consented
    
    # Foreign keys
    add_foreign_key :pageviews, :tenants
    add_foreign_key :pageviews, :users
    add_foreign_key :pageviews, :posts
    add_foreign_key :pageviews, :pages
  end
end
