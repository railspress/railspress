class AddTemplateToPages < ActiveRecord::Migration[7.1]
  def change
    add_reference :pages, :page_template, null: true, foreign_key: true
  end
end
