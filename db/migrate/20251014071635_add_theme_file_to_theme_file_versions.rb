class AddThemeFileToThemeFileVersions < ActiveRecord::Migration[7.1]
  def change
    add_reference :theme_file_versions, :theme_file, null: true, foreign_key: true
  end
end
