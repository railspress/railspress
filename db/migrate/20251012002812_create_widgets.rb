class CreateWidgets < ActiveRecord::Migration[7.1]
  def change
    create_table :widgets do |t|
      t.string :title
      t.string :widget_type
      t.text :content
      t.string :sidebar_location
      t.integer :position
      t.text :settings
      t.boolean :active

      t.timestamps
    end
  end
end
