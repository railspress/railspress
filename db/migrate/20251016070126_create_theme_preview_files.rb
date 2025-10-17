class CreateThemePreviewFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :theme_preview_files do |t|
      t.references :builder_theme, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :file_path, null: false
      t.string :file_type, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :theme_preview_files, [:builder_theme_id, :file_path], unique: true
    add_index :theme_preview_files, :file_type
  end
end
