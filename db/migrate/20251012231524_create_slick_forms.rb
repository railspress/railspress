class CreateSlickForms < ActiveRecord::Migration[7.1]
  def change
    create_table :slick_forms do |t|
      t.string :name, null: false
      t.string :title
      t.text :description
      t.json :fields, default: []
      t.json :settings, default: {}
      t.boolean :active, default: true
      t.integer :submissions_count, default: 0
      t.integer :tenant_id
      t.timestamps
      
      t.index :name
      t.index :active
      t.index :tenant_id
    end
  end
end
