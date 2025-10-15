class CreateThemeVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :theme_versions do |t|
      t.string :theme_name
      t.string :version
      t.boolean :is_live
      t.boolean :is_preview
      t.references :user, null: false, foreign_key: true
      t.text :change_summary
      t.datetime :published_at

      t.timestamps
    end
  end
end
