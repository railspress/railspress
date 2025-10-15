class CreateBuilderThemes < ActiveRecord::Migration[7.1]
  def change
    create_table :builder_themes do |t|
      t.string :theme_name, null: false
      t.string :label, null: false
      t.integer :parent_version_id
      t.string :checksum, null: false
      t.boolean :published, default: false, null: false
      t.references :user, null: false, foreign_key: true
      t.text :summary

      t.timestamps
    end
    
    add_index :builder_themes, [:theme_name, :published]
    add_index :builder_themes, :parent_version_id
    add_index :builder_themes, :checksum, unique: true
  end
end
