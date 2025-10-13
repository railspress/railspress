class CreateContentTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :content_types do |t|
      t.string :ident, null: false
      t.string :label, null: false
      t.string :singular, null: false
      t.string :plural, null: false
      t.text :description
      t.string :icon
      t.boolean :public, default: true
      t.boolean :hierarchical, default: false
      t.boolean :has_archive, default: true
      t.integer :menu_position
      t.text :supports # JSON array of features: title, editor, excerpt, thumbnail, comments, etc.
      t.text :capabilities # JSON object for custom capabilities
      t.string :rest_base
      t.boolean :active, default: true
      t.references :tenant, null: true, foreign_key: true

      t.timestamps
    end
    add_index :content_types, :ident, unique: true
    add_index :content_types, :active
  end
end
