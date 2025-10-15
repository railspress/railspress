class CreateBuilderPageSections < ActiveRecord::Migration[7.1]
  def change
    create_table :builder_page_sections do |t|
      t.references :builder_page, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :section_id, null: false
      t.string :section_type, null: false
      t.text :settings, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    
    add_index :builder_page_sections, [:builder_page_id, :position]
    add_index :builder_page_sections, [:builder_page_id, :section_id], unique: true
  end
end
