class CreateThemeFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :theme_files do |t|
      t.string :theme_name
      t.string :file_path
      t.string :file_type
      t.integer :current_version

      t.timestamps
    end
  end
end
