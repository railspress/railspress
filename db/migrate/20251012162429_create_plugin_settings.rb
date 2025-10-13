class CreatePluginSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :plugin_settings do |t|
      t.string :plugin_name, null: false
      t.string :key, null: false
      t.text :value
      t.string :setting_type, default: 'string'
      t.integer :tenant_id

      t.timestamps
    end
    
    add_index :plugin_settings, [:plugin_name, :key], unique: true
    add_index :plugin_settings, :plugin_name
    add_index :plugin_settings, :tenant_id
  end
end
