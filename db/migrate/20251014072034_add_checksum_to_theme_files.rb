class AddChecksumToThemeFiles < ActiveRecord::Migration[7.1]
  def change
    add_column :theme_files, :current_checksum, :string
  end
end
