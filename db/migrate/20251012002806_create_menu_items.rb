class CreateMenuItems < ActiveRecord::Migration[7.1]
  def change
    create_table :menu_items do |t|
      t.references :menu, null: false, foreign_key: true
      t.string :label
      t.string :url
      t.integer :parent_id
      t.integer :position
      t.string :target
      t.string :css_class

      t.timestamps
    end
    add_index :menu_items, :parent_id
  end
end
