class AddTrashToMedia < ActiveRecord::Migration[7.1]
  def change
    add_column :media, :deleted_at, :datetime
    add_reference :media, :trashed_by, null: true, foreign_key: { to_table: :users }
    add_index :media, :deleted_at
  end
end
