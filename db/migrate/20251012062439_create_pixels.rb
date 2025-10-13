class CreatePixels < ActiveRecord::Migration[7.1]
  def change
    create_table :pixels do |t|
      t.string :name, null: false
      t.string :pixel_type, default: 'custom', null: false
      t.string :provider
      t.string :pixel_id
      t.text :custom_code
      t.string :position, default: 'head', null: false
      t.boolean :active, default: true
      t.text :notes
      t.integer :tenant_id

      t.timestamps
    end
    
    add_index :pixels, :tenant_id
    add_index :pixels, [:active, :position]
    add_foreign_key :pixels, :tenants
  end
end
