class CreateArchivedPageviews < ActiveRecord::Migration[7.1]
  def change
    create_table :archived_pageviews do |t|
      # Original pageview fields
      t.string :path
      t.string :title
      t.text :referrer
      t.text :user_agent
      t.string :browser
      t.string :device
      t.string :os
      t.string :ip_hash
      t.string :session_id
      t.references :user, null: true, foreign_key: true
      t.references :post, null: true, foreign_key: true
      t.references :page, null: true, foreign_key: true
      t.boolean :unique_visitor, default: false
      t.boolean :returning_visitor, default: false
      t.boolean :bot, default: false
      t.boolean :consented, default: false
      t.datetime :visited_at
      t.json :metadata
      t.references :tenant, null: false, foreign_key: true
      
      # Engagement fields
      t.integer :reading_time
      t.integer :scroll_depth
      t.decimal :completion_rate, precision: 5, scale: 2
      t.integer :time_on_page
      t.boolean :exit_intent, default: false
      
      # Geolocation fields
      t.string :country_code
      t.string :country_name
      t.string :city
      t.string :region
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :timezone
      
      # Medium-like reader fields
      t.boolean :is_reader, default: false
      t.integer :engagement_score, default: 0
      
      # Archive metadata
      t.datetime :archived_at
      t.string :archive_batch_id
      
      t.timestamps
    end
    
    add_index :archived_pageviews, :visited_at
    add_index :archived_pageviews, :session_id
    add_index :archived_pageviews, :country_code
    add_index :archived_pageviews, :device
    add_index :archived_pageviews, :browser
    add_index :archived_pageviews, :is_reader
    add_index :archived_pageviews, :archived_at
    add_index :archived_pageviews, :archive_batch_id
    add_index :archived_pageviews, :tenant_id unless index_exists?(:archived_pageviews, :tenant_id)
  end
end
