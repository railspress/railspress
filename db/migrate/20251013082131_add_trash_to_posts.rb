class AddTrashToPosts < ActiveRecord::Migration[7.1]
  def change
    add_reference :posts, :trashed_by, null: true, foreign_key: { to_table: :users }
  end
end
