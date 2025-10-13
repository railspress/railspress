class CreateApiTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :api_tokens do |t|
      t.string :name, null: false
      t.string :token, null: false
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: 'public'
      t.json :permissions, default: {}
      t.datetime :expires_at
      t.datetime :last_used_at
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :api_tokens, :token, unique: true
    add_index :api_tokens, [:user_id, :name], unique: true
    add_index :api_tokens, :role
    add_index :api_tokens, :active
  end
end
