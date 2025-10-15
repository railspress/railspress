class AddIsLiveToThemeFileVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :theme_file_versions, :is_live, :boolean
  end
end
