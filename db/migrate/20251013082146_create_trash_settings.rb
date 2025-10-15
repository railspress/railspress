class CreateTrashSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :trash_settings do |t|
      t.boolean :auto_cleanup_enabled
      t.integer :cleanup_after_days
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
