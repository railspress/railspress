class CreateChannelOverrides < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_overrides do |t|
      t.references :channel, null: false, foreign_key: true
      t.string :resource_type, null: false
      t.integer :resource_id
      t.string :kind, null: false # 'override' or 'exclude'
      t.string :path, null: false
      t.json :data, default: {}
      t.boolean :enabled, default: true

      t.timestamps
    end
    
    add_index :channel_overrides, [:resource_type, :resource_id]
    add_index :channel_overrides, [:channel_id, :resource_type, :resource_id]
    add_index :channel_overrides, :path
  end
end
