class AddSidebarOrderToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :sidebar_order, :text
  end
end
