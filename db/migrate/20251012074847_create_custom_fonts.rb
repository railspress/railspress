class CreateCustomFonts < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_fonts do |t|
      t.string :name, null: false
      t.string :family, null: false  # Font family name (e.g., 'Roboto')
      t.string :source, null: false, default: 'google'  # google, custom, adobe, bunny
      t.string :url  # URL for custom fonts or Google Fonts URL
      t.text :weights  # JSON: ['300', '400', '700', '900']
      t.text :styles  # JSON: ['normal', 'italic']
      t.string :fallback, default: 'sans-serif'  # serif, sans-serif, monospace
      t.boolean :active, default: true
      t.integer :tenant_id

      t.timestamps
    end
    
    add_index :custom_fonts, :name
    add_index :custom_fonts, :family
    add_index :custom_fonts, :source
    add_index :custom_fonts, :active
    add_index :custom_fonts, :tenant_id
    add_foreign_key :custom_fonts, :tenants
  end
end
