class CreateBuilderThemeSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :builder_theme_snapshots do |t|
      t.string :theme_name, null: false
      t.references :builder_theme, null: false, foreign_key: true
      t.text :settings_data, null: false
      t.text :sections_data, null: false
      t.string :checksum, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :builder_theme_snapshots, [:theme_name, :created_at]
    add_index :builder_theme_snapshots, :checksum, unique: true
  end
end
