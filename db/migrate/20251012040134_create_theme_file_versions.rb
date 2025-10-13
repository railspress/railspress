class CreateThemeFileVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :theme_file_versions do |t|
      t.string :theme_name, null: false
      t.string :file_path, null: false
      t.text :content
      t.integer :file_size
      t.references :user, foreign_key: true
      t.string :change_summary

      t.timestamps
    end
    
    add_index :theme_file_versions, [:theme_name, :file_path]
    add_index :theme_file_versions, :created_at
  end
end
