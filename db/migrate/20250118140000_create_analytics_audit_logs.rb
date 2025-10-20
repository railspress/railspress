class CreateAnalyticsAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :analytics_audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.references :admin_user, null: true, foreign_key: { to_table: :users }
      t.references :tenant, null: true, foreign_key: true
      t.string :data_type, null: false
      t.string :action, null: false
      t.datetime :timestamp, null: false
      t.string :ip_address
      t.text :user_agent
      t.text :details

      t.timestamps
    end

    add_index :analytics_audit_logs, :user_id unless index_exists?(:analytics_audit_logs, :user_id)
    add_index :analytics_audit_logs, :admin_user_id unless index_exists?(:analytics_audit_logs, :admin_user_id)
    add_index :analytics_audit_logs, :tenant_id unless index_exists?(:analytics_audit_logs, :tenant_id)
    add_index :analytics_audit_logs, :data_type unless index_exists?(:analytics_audit_logs, :data_type)
    add_index :analytics_audit_logs, :action unless index_exists?(:analytics_audit_logs, :action)
    add_index :analytics_audit_logs, :timestamp unless index_exists?(:analytics_audit_logs, :timestamp)
  end
end