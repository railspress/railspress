class CreateRedirects < ActiveRecord::Migration[7.1]
  def change
    create_table :redirects do |t|
      t.string :from_path, null: false
      t.string :to_path, null: false
      t.integer :redirect_type, default: 0, null: false
      t.integer :status_code, default: 301, null: false
      t.integer :hits_count, default: 0
      t.boolean :active, default: true
      t.text :notes
      t.integer :tenant_id

      t.timestamps
    end
    
    add_index :redirects, :from_path
    add_index :redirects, :tenant_id
    add_index :redirects, [:from_path, :active]
    add_foreign_key :redirects, :tenants
  end
end
