class CreateThemePreviewSections < ActiveRecord::Migration[7.1]
  def change
    create_table :theme_preview_sections do |t|
      t.references :theme_preview, null: false, foreign_key: true
      t.string :section_id, null: false
      t.string :section_type, null: false
      t.text :settings, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :theme_preview_sections, [:theme_preview_id, :section_id], unique: true
    add_index :theme_preview_sections, [:theme_preview_id, :position]
  end
end
