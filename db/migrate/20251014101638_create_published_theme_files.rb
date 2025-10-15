class CreatePublishedThemeFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :published_theme_files do |t|
      t.references :published_theme_version, null: false, foreign_key: true
      t.string :file_path
      t.string :file_type
      t.text :content
      t.string :checksum

      t.timestamps
    end
  end
end
