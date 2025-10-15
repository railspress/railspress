class CreateBuilderPages < ActiveRecord::Migration[7.1]
  def change
    create_table :builder_pages do |t|
      t.references :builder_theme, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :template_name, null: false
      t.string :page_title, null: false
      t.text :settings, null: false
      t.text :sections, null: false
      t.integer :position, null: false, default: 0
      t.boolean :published, default: false, null: false

      t.timestamps
    end
    
    add_index :builder_pages, [:builder_theme_id, :template_name], unique: true
    add_index :builder_pages, [:builder_theme_id, :position]
    add_index :builder_pages, [:builder_theme_id, :published]
  end
end
