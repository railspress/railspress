class CreateWebhooks < ActiveRecord::Migration[7.1]
  def change
    create_table :webhooks do |t|
      t.string :url, null: false
      t.text :events  # Serialized array of event names
      t.boolean :active, default: true
      t.string :secret_key, null: false
      t.string :name
      t.text :description
      t.integer :retry_limit, default: 3
      t.integer :timeout, default: 30
      t.datetime :last_delivered_at
      t.integer :total_deliveries, default: 0
      t.integer :failed_deliveries, default: 0

      t.timestamps
    end
    
    add_index :webhooks, :url
    add_index :webhooks, :active
  end
end
