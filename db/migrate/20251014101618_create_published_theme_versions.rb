class CreatePublishedThemeVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :published_theme_versions do |t|
      t.string :theme_name
      t.integer :version_number
      t.datetime :published_at
      t.references :published_by, polymorphic: true, null: false
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
