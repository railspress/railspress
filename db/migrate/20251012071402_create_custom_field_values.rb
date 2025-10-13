class CreateCustomFieldValues < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_field_values do |t|
      t.integer :custom_field_id, null: false
      t.integer :post_id
      t.integer :page_id
      t.string :meta_key, null: false  # Field name
      t.text :value  # Field value (serialized if complex)
      t.integer :tenant_id

      t.timestamps
    end
    
    add_index :custom_field_values, :custom_field_id
    add_index :custom_field_values, :post_id
    add_index :custom_field_values, :page_id
    add_index :custom_field_values, :meta_key
    add_index :custom_field_values, :tenant_id
    add_index :custom_field_values, [:post_id, :meta_key]
    add_index :custom_field_values, [:page_id, :meta_key]
    
    add_foreign_key :custom_field_values, :custom_fields
    add_foreign_key :custom_field_values, :posts
    add_foreign_key :custom_field_values, :pages
    add_foreign_key :custom_field_values, :tenants
  end
end
