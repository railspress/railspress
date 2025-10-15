class AddTrashToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :deleted_at, :datetime
    add_reference :comments, :trashed_by, null: true, foreign_key: { to_table: :users }
    add_index :comments, :deleted_at
  end
end
