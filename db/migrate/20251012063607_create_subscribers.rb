class CreateSubscribers < ActiveRecord::Migration[7.1]
  def change
    create_table :subscribers do |t|
      t.string :email, null: false
      t.string :name
      t.string :status, default: 'pending', null: false
      t.string :source
      t.datetime :confirmed_at
      t.datetime :unsubscribed_at
      t.string :unsubscribe_token
      t.string :ip_address
      t.string :user_agent
      t.text :metadata
      t.text :tags
      t.text :lists
      t.integer :tenant_id

      t.timestamps
    end
    
    add_index :subscribers, :email
    add_index :subscribers, :status
    add_index :subscribers, :unsubscribe_token, unique: true
    add_index :subscribers, :tenant_id
    add_index :subscribers, [:tenant_id, :email], unique: true
    add_foreign_key :subscribers, :tenants
  end
end
