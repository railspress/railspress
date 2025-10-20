class CreateAnalyticsDataDeletions < ActiveRecord::Migration[7.1]
  def change
    create_table :analytics_data_deletions do |t|
      t.references :user, null: true, foreign_key: true
      t.references :admin_user, null: true, foreign_key: { to_table: :users }
      t.references :tenant, null: true, foreign_key: true
      t.text :data_types, null: false
      t.datetime :timestamp, null: false
      t.text :deletion_details

      t.timestamps
    end

    add_index :analytics_data_deletions, :user_id unless index_exists?(:analytics_data_deletions, :user_id)
    add_index :analytics_data_deletions, :admin_user_id unless index_exists?(:analytics_data_deletions, :admin_user_id)
    add_index :analytics_data_deletions, :tenant_id unless index_exists?(:analytics_data_deletions, :tenant_id)
    add_index :analytics_data_deletions, :timestamp unless index_exists?(:analytics_data_deletions, :timestamp)
  end
end
