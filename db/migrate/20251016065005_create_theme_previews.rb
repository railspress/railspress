class CreateThemePreviews < ActiveRecord::Migration[7.1]
  def change
    create_table :theme_previews do |t|
      t.references :builder_theme, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :template_name, null: false

      t.timestamps
    end

    add_index :theme_previews, [:builder_theme_id, :template_name], unique: true
  end
end
