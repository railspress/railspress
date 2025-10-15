class AddTrashToPages < ActiveRecord::Migration[7.1]
  def change
    add_reference :pages, :trashed_by, null: true, foreign_key: { to_table: :users }
  end
end
