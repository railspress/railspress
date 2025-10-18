class CreateThemePreviewBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :theme_preview_blocks do |t|
      t.references :theme_preview_section, null: false, foreign_key: true
      t.string :block_type
      t.string :block_id
      t.text :settings
      t.integer :position

      t.timestamps
    end
  end
end
