class AddThemeVersionToThemeFileVersions < ActiveRecord::Migration[7.1]
  def change
    add_reference :theme_file_versions, :theme_version, null: true, foreign_key: true
  end
end
