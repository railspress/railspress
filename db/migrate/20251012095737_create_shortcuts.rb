class CreateShortcuts < ActiveRecord::Migration[7.1]
  def change
    create_table :shortcuts do |t|
      t.string :name
      t.text :description
      t.string :keybinding
      t.string :action_type
      t.string :action_value
      t.string :icon
      t.string :category
      t.integer :position
      t.boolean :active
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
