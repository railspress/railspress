class CreateThemeVersionFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :theme_version_files do |t|
      t.references :theme_version, null: false, foreign_key: true
      t.string :file_path
      t.string :file_type
      t.text :content
      t.integer :file_size

      t.timestamps
    end
  end
end
