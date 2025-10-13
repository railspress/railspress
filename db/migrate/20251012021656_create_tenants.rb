class CreateTenants < ActiveRecord::Migration[7.1]
  def change
    create_table :tenants do |t|
      t.string :name, null: false
      t.string :domain, index: { unique: true }
      t.string :subdomain, index: { unique: true }
      t.string :theme, default: 'default'
      t.text :settings
      t.string :locales, default: 'en'
      t.boolean :active, default: true, null: false
      t.string :storage_type, default: 'local' # local, s3
      t.string :storage_bucket
      t.string :storage_region
      t.string :storage_access_key
      t.string :storage_secret_key
      t.string :storage_endpoint
      t.string :storage_path

      t.timestamps
    end
    
    add_index :tenants, :active
  end
end
