class CreatePageTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :page_templates do |t|
      t.string :name, null: false
      t.string :template_type, null: false
      t.text :html_content
      t.text :css_content
      t.text :js_content
      t.boolean :active, default: true
      t.integer :position, default: 0
      t.references :tenant, null: false, foreign_key: true
      
      t.timestamps
    end
    
    add_index :page_templates, [:tenant_id, :template_type]
    add_index :page_templates, [:tenant_id, :active]
  end
end
