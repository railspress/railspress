class CreateStorageProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :storage_providers do |t|
      t.string :name
      t.string :provider_type
      t.text :config
      t.boolean :active
      t.integer :position
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
