class CreateArchivedAnalyticsEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :archived_analytics_events do |t|
      # Original event fields
      t.string :event_name, null: false
      t.json :properties
      t.string :session_id
      t.references :user, null: true, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.datetime :created_at
      
      # Archive metadata
      t.datetime :archived_at
      t.string :archive_batch_id
      
      t.timestamp :updated_at
    end
    
    add_index :archived_analytics_events, :event_name
    add_index :archived_analytics_events, :session_id
    add_index :archived_analytics_events, :created_at
    add_index :archived_analytics_events, :archived_at
    add_index :archived_analytics_events, :archive_batch_id
    add_index :archived_analytics_events, :tenant_id unless index_exists?(:archived_analytics_events, :tenant_id)
  end
end
