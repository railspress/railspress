class MakeThemePreviewsContentNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :theme_previews, :content, true
  end
end
