class AddPreferredEditorToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :preferred_editor, :string
  end
end
