class AddThemeSettingsToThemePreviews < ActiveRecord::Migration[7.1]
  def change
    add_column :theme_previews, :theme_settings, :text
    add_column :theme_previews, :theme_settings_json, :json
  end
end
