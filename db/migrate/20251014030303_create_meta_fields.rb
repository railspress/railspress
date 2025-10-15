class CreateMetaFields < ActiveRecord::Migration[7.1]
  def change
    create_table :meta_fields do |t|
      t.references :metable, null: false, polymorphic: true, index: true
      t.string :key, null: false
      t.text :value
      t.boolean :immutable, default: false, null: false

      t.timestamps
    end

    # Add indexes for performance
    add_index :meta_fields, [:metable_type, :metable_id, :key], unique: true, name: 'index_meta_fields_on_metable_and_key'
    add_index :meta_fields, :key
    add_index :meta_fields, :immutable
  end
end
