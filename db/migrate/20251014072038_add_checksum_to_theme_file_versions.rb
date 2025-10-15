class AddChecksumToThemeFileVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :theme_file_versions, :file_checksum, :string
  end
end
