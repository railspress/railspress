class AddMonacoThemeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :monaco_theme, :string
  end
end
