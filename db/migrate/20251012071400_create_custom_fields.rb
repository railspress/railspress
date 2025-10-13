class CreateCustomFields < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_fields do |t|
      t.integer :field_group_id, null: false
      t.string :name, null: false  # Field name/key (e.g., 'author_bio')
      t.string :label, null: false  # Display label (e.g., 'Author Biography')
      t.string :field_type, null: false  # text, textarea, number, select, etc.
      t.text :instructions  # Help text
      t.boolean :required, default: false
      t.text :default_value
      t.text :choices  # JSON: for select, radio, checkbox
      t.text :conditional_logic  # JSON: show/hide based on other fields
      t.integer :position, default: 0
      t.text :settings  # JSON: additional field-specific settings

      t.timestamps
    end
    
    add_index :custom_fields, :field_group_id
    add_index :custom_fields, :name
    add_index :custom_fields, :field_type
    add_index :custom_fields, :position
    add_foreign_key :custom_fields, :field_groups
  end
end
