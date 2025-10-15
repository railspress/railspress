class AddVersionNumberToThemeFileVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :theme_file_versions, :version_number, :integer
  end
end
