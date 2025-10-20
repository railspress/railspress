class CreateAnalyticsEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :analytics_events do |t|
      t.string :event_name
      t.text :properties
      t.string :session_id
      t.integer :user_id
      t.string :path
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
