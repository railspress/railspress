class CreateTermRelationships < ActiveRecord::Migration[7.1]
  def change
    create_table :term_relationships do |t|
      t.references :term, null: false, foreign_key: true
      t.references :object, polymorphic: true, null: false
      t.integer :term_order

      t.timestamps
    end
  end
end
