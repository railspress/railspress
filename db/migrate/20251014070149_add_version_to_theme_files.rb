class AddVersionToThemeFiles < ActiveRecord::Migration[7.1]
  def change
    add_reference :theme_files, :theme_version, null: true, foreign_key: true
  end
end
