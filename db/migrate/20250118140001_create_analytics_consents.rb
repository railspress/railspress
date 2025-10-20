class CreateAnalyticsConsents < ActiveRecord::Migration[7.1]
  def change
    create_table :analytics_consents do |t|
      t.references :user, null: true, foreign_key: true
      t.references :tenant, null: true, foreign_key: true
      t.string :consent_type, null: false
      t.boolean :granted, null: false
      t.string :purpose
      t.datetime :timestamp, null: false
      t.string :ip_address
      t.text :user_agent
      t.text :consent_details

      t.timestamps
    end

    add_index :analytics_consents, :user_id unless index_exists?(:analytics_consents, :user_id)
    add_index :analytics_consents, :tenant_id unless index_exists?(:analytics_consents, :tenant_id)
    add_index :analytics_consents, :consent_type unless index_exists?(:analytics_consents, :consent_type)
    add_index :analytics_consents, :granted unless index_exists?(:analytics_consents, :granted)
    add_index :analytics_consents, :timestamp unless index_exists?(:analytics_consents, :timestamp)
  end
end
