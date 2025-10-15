class RemoveFilePathFromThemeFileVersions < ActiveRecord::Migration[7.1]
  def change
    remove_column :theme_file_versions, :file_path, :string
  end
end
