class RemoveThemeNameFromThemeFileVersions < ActiveRecord::Migration[7.1]
  def change
    remove_column :theme_file_versions, :theme_name, :string
  end
end
