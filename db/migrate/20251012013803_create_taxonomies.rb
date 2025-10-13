class CreateTaxonomies < ActiveRecord::Migration[7.1]
  def change
    create_table :taxonomies do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.boolean :hierarchical
      t.text :object_types
      t.text :settings

      t.timestamps
    end
  end
end
