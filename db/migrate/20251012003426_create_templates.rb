class CreateTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :templates do |t|
      t.string :name
      t.text :description
      t.string :template_type
      t.text :html_content
      t.text :css_content
      t.text :js_content
      t.references :theme, null: false, foreign_key: true
      t.boolean :active

      t.timestamps
    end
  end
end
