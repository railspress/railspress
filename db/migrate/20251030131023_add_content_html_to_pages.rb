class AddContentHtmlToPages < ActiveRecord::Migration[7.1]
  def change
    add_column :pages, :content_html, :text
  end
end
