class CreateFieldGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :field_groups do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, default: 0
      t.boolean :active, default: true
      t.text :location_rules  # JSON: {post_type: ['post'], page_template: [], etc}
      t.integer :tenant_id

      t.timestamps
    end
    
    add_index :field_groups, :slug
    add_index :field_groups, :tenant_id
    add_index :field_groups, :active
    add_index :field_groups, :position
    add_foreign_key :field_groups, :tenants
  end
end
