class CreateBuilderThemeFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :builder_theme_files do |t|
      t.references :builder_theme, null: false, foreign_key: true
      t.string :path, null: false
      t.text :content, null: false
      t.string :checksum, null: false
      t.integer :file_size

      t.timestamps
    end
    
    add_index :builder_theme_files, [:builder_theme_id, :path], unique: true
    add_index :builder_theme_files, :checksum
  end
end
