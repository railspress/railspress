class CreateTerms < ActiveRecord::Migration[7.1]
  def change
    create_table :terms do |t|
      t.references :taxonomy, null: false, foreign_key: true
      t.string :name
      t.string :slug
      t.text :description
      t.integer :parent_id
      t.integer :count
      t.text :metadata

      t.timestamps
    end
    add_index :terms, :parent_id
  end
end
