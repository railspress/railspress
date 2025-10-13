class CreateThemes < ActiveRecord::Migration[7.1]
  def change
    create_table :themes do |t|
      t.string :name
      t.text :description
      t.string :author
      t.string :version
      t.boolean :active
      t.text :settings

      t.timestamps
    end
  end
end
