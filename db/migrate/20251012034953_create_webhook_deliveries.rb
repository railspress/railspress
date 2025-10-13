class CreateWebhookDeliveries < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook, null: false, foreign_key: true
      t.string :event_type, null: false
      t.json :payload
      t.string :status, default: 'pending'  # pending, success, failed
      t.integer :response_code
      t.text :response_body
      t.text :error_message
      t.datetime :delivered_at
      t.integer :retry_count, default: 0
      t.datetime :next_retry_at
      t.string :request_id  # For tracking/debugging

      t.timestamps
    end
    
    add_index :webhook_deliveries, :event_type
    add_index :webhook_deliveries, :status
    add_index :webhook_deliveries, :delivered_at
    add_index :webhook_deliveries, [:webhook_id, :created_at]
  end
end
